import Foundation
import UniformTypeIdentifiers
import CoreGraphics

// MARK: - File Import Manager

class FileImportManager {
    /// Parse any supported file type off the main thread to avoid UI jank.
    static func parseAsync(url: URL) async throws -> [Transaction] {
        try await Task.detached(priority: .userInitiated) {
            let ext = url.pathExtension.lowercased()
            if ext == "csv" || ext == "txt" {
                return try parseCSV(url: url)
            } else if ext == "pdf" {
                return try parsePDF(url: url)
            } else {
                return try parseExcel(url: url)
            }
        }.value
    }
    
    // MARK: - CSV Import
    
    static func parseCSV(url: URL) throws -> [Transaction] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw ImportError.emptyFile
        }
        
        let headers = parseCSVLine(lines[0]).map { $0.lowercased() }
        
        // Auto-detect columns
        let dateCol = headers.firstIndex { $0.contains("date") }
        let descCol = headers.firstIndex { $0.contains("description") || $0.contains("memo") || $0.contains("merchant") }
        let amountCol = headers.firstIndex { $0.contains("amount") || $0.contains("debit") || $0.contains("withdrawal") }
        let creditCol = headers.firstIndex { $0.contains("credit") || $0.contains("deposit") }
        
        var transactions: [Transaction] = []
        
        for i in 1..<lines.count {
            let values = parseCSVLine(lines[i])
            guard values.count > max(dateCol ?? 0, descCol ?? 0, amountCol ?? 0) else { continue }
            
            // Parse date
            var date = Date()
            if let col = dateCol, col < values.count {
                date = parseDate(values[col]) ?? Date()
            }
            
            // Parse description
            var description = ""
            if let col = descCol, col < values.count {
                description = values[col].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Parse amount
            var amount: Double = 0
            var isIncome = false
            
            if let col = amountCol, col < values.count {
                let amountStr = values[col].replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespaces)
                amount = Double(amountStr) ?? 0
                
                if amount < 0 {
                    amount = abs(amount)
                    isIncome = false
                } else if amount > 0 {
                    // Check if there's a separate credit column
                    if creditCol != nil {
                        isIncome = false // This is debit column
                    } else {
                        isIncome = CategoryDetector.isLikelyIncome(description, amount: amount)
                    }
                }
            }
            
            // Check credit column separately
            if let col = creditCol, col < values.count {
                let creditStr = values[col].replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let creditAmount = Double(creditStr), creditAmount > 0 {
                    amount = creditAmount
                    isIncome = true
                }
            }
            
            guard amount > 0 else { continue }
            
            // Detect category
            let category = isIncome ? TransactionCategory.income : CategoryDetector.detect(description)
            
            let transaction = Transaction(
                date: date,
                description: description,
                amount: amount,
                category: category,
                merchant: extractMerchant(description),
                isIncome: isIncome,
                source: .csvImport
            )
            
            transactions.append(transaction)
        }
        
        return transactions
    }
    
    // MARK: - Excel Import (TSV/CSV from Numbers/Excel)
    
    static func parseExcel(url: URL) throws -> [Transaction] {
        // For now, treat Excel exports as CSV/TSV
        // A full implementation would use a library like CoreXLSX
        return try parseCSV(url: url)
    }
    
    // MARK: - PDF Import (Text extraction)
    
    static func parsePDF(url: URL) throws -> [Transaction] {
        guard let pdfDocument = CGPDFDocument(url as CFURL) else {
            throw ImportError.invalidFile
        }
        
        var fullText = ""
        
        for pageNum in 1...pdfDocument.numberOfPages {
            guard let page = pdfDocument.page(at: pageNum) else { continue }
            
            // Extract text using basic PDF parsing
            // For production, use PDFKit or a dedicated library
            if let pageText = extractTextFromPDFPage(page) {
                fullText += pageText + "\n"
            }
        }
        
        return extractTransactionsFromText(fullText)
    }
    
    // MARK: - AI Text Extraction
    
    static func extractTransactionsFromText(_ text: String) -> [Transaction] {
        var transactions: [Transaction] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        // Pattern: Look for lines with dates and amounts
        let datePatterns = [
            "\\d{1,2}/\\d{1,2}/\\d{2,4}",  // MM/DD/YYYY
            "\\d{4}-\\d{2}-\\d{2}",         // YYYY-MM-DD
            "\\d{1,2}-\\d{1,2}-\\d{2,4}"    // MM-DD-YYYY
        ]
        
        let amountPattern = "\\$?[\\d,]+\\.\\d{2}"
        
        for line in lines {
            var foundDate: Date?
            var foundAmount: Double?
            var description = line
            
            // Find date
            for pattern in datePatterns {
                if let range = line.range(of: pattern, options: .regularExpression) {
                    let dateStr = String(line[range])
                    foundDate = parseDate(dateStr)
                    description = line.replacingCharacters(in: range, with: "")
                    break
                }
            }
            
            // Find amount
            if let range = description.range(of: amountPattern, options: .regularExpression) {
                let amountStr = String(description[range])
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: ",", with: "")
                foundAmount = Double(amountStr)
                description = description.replacingCharacters(in: range, with: "")
            }
            
            // If we found both date and amount, create transaction
            if let date = foundDate, let amount = foundAmount, amount > 0 {
                description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                
                guard !description.isEmpty else { continue }
                
                let isIncome = CategoryDetector.isLikelyIncome(description, amount: amount)
                let category = isIncome ? .income : CategoryDetector.detect(description)
                
                let transaction = Transaction(
                    date: date,
                    description: description,
                    amount: amount,
                    category: category,
                    merchant: extractMerchant(description),
                    isIncome: isIncome,
                    source: .aiExtracted
                )
                
                transactions.append(transaction)
            }
        }
        
        return transactions
    }
    
    // MARK: - Helpers
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        
        return result.map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private static func parseDate(_ string: String) -> Date? {
        let formatters = [
            "MM/dd/yyyy",
            "M/d/yyyy",
            "MM/dd/yy",
            "M/d/yy",
            "yyyy-MM-dd",
            "MM-dd-yyyy",
            "M-d-yyyy"
        ]
        
        let cleaned = string.trimmingCharacters(in: .whitespaces)
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }
        
        return nil
    }
    
    private static func extractMerchant(_ description: String) -> String {
        // Simple extraction: take first few words
        let words = description.components(separatedBy: .whitespaces).prefix(3)
        return words.joined(separator: " ")
    }
    
    private static func extractTextFromPDFPage(_ page: CGPDFPage) -> String? {
        // Basic implementation - for production use PDFKit
        // This is a placeholder that returns nil
        // Real implementation would use CGPDFOperatorTable and CGPDFScanner
        return nil
    }
}

// MARK: - Errors

enum ImportError: Error, LocalizedError {
    case emptyFile
    case invalidFile
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyFile: return "The file is empty"
        case .invalidFile: return "Could not read the file"
        case .parseError(let msg): return "Parse error: \(msg)"
        }
    }
}

// MARK: - Supported File Types

extension UTType {
    static let csvFile = UTType(filenameExtension: "csv") ?? .commaSeparatedText
}

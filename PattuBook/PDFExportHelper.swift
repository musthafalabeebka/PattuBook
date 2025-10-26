//
//  PDFExportHelper.swift
//  PattuBook
//
//  Created by Musthafa Labeeb K A on 26/10/25.
//


import PDFKit

class PDFExportHelper {
    static func generateCustomerStatement(customer: Customer) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Pattu Book",
            kCGPDFContextAuthor: "Shop Owner",
            kCGPDFContextTitle: "Customer Statement - \(customer.name)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let title = "Customer Statement"
            title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Customer Info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            "Name: \(customer.name)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
            yPosition += 20
            "Phone: \(customer.phone)".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
            yPosition += 20
            "Total Due: ₹\(String(format: "%.2f", customer.totalDue))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
            yPosition += 40
            
            // Transactions
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12)
            ]
            "Date\t\tType\t\tAmount\t\tNote".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
            yPosition += 25
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            
            for transaction in customer.transactionsArray {
                let dateStr = dateFormatter.string(from: transaction.date)
                let typeStr = transaction.type.capitalized
                let amountStr = String(format: "%.2f", transaction.amount)
                let noteStr = transaction.note ?? "-"
                
                let line = "\(dateStr)\t\(typeStr)\t₹\(amountStr)\t\(noteStr)"
                line.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: infoAttributes)
                yPosition += 20
                
                if yPosition > pageHeight - 50 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }
        
        return data
    }
}

////
////  ApplyFineView.swift
////  Team7LibraryManagementSystem
////
////  Created by Rakshit  on 24/02/25.
////
//
//import Foundation
//// New Apply Fine View
//struct ApplyFineView: View {
//    @Environment(\.dismiss) var dismiss
//    let book: IssuedBook
//    @State private var fineAmount = "10.00"
//    @State private var discount = "5.00"
//    @State private var reason = "Late return"
//    
//    var additionalCharges: Double {
//        return 10 * 0.50 // 10 days * $0.50
//    }
//    
//    var totalFine: Double {
//        return (Double(fineAmount) ?? 0) + additionalCharges - (Double(discount) ?? 0)
//    }
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 24) {
//                    // Book Info
//                    HStack(spacing: 16) {
//                        Image(book.coverImage)
//                            .resizable()
//                            .frame(width: 80, height: 100)
//                            .cornerRadius(8)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(book.title)
//                                .font(.headline)
//                            
//                            Text(book.author)
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                            
//                            HStack {
//                                Image(systemName: "calendar")
//                                    .foregroundColor(.gray)
//                                Text("Due: Jan 15, 2024")
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                            }
//                            
//                            HStack {
//                                Text("Overdue: 10 days")
//                                    .font(.subheadline)
//                                    .foregroundColor(.red)
//                                
//                                Text("OVERDUE")
//                                    .font(.caption)
//                                    .padding(.horizontal, 8)
//                                    .padding(.vertical, 4)
//                                    .background(Color.red.opacity(0.1))
//                                    .foregroundColor(.red)
//                                    .cornerRadius(4)
//                            }
//                        }
//                    }
//                    
//                    // Issue Summary
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Issue Summary")
//                            .font(.headline)
//                        
//                        HStack {
//                            Text("Issue Date")
//                                .foregroundColor(.gray)
//                            Spacer()
//                            Text("Feb 15, 2024")
//                        }
//                        
//                        HStack {
//                            Text("Additional charges (10 days × $0.50)")
//                                .foregroundColor(.gray)
//                            Spacer()
//                            Text("$\(String(format: "%.2f", additionalCharges))")
//                        }
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//                    
//                    // Fine Details
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("Fine")
//                            .font(.headline)
//                            .foregroundColor(.blue)
//                        
//                        // Fine Amount
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Fine Amount")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                            
//                            TextField("Enter fine amount", text: $fineAmount)
//                                .keyboardType(.decimalPad)
//                                .padding()
//                                .background(Color(.systemGray6))
//                                .cornerRadius(10)
//                        }
//                        
//                        // Reason
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Reason")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                            
//                            Menu {
//                                Button("Late return") { reason = "Late return" }
//                                Button("Damaged book") { reason = "Damaged book" }
//                                Button("Lost book") { reason = "Lost book" }
//                            } label: {
//                                HStack {
//                                    Text(reason)
//                                    Spacer()
//                                    Image(systemName: "chevron.down")
//                                        .foregroundColor(.gray)
//                                }
//                                .padding()
//                                .background(Color(.systemGray6))
//                                .cornerRadius(10)
//                            }
//                        }
//                        
//                        // Discount
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text("Discount")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                            
//                            TextField("Enter discount amount", text: $discount)
//                                .keyboardType(.decimalPad)
//                                .padding()
//                                .background(Color(.systemGray6))
//                                .cornerRadius(10)
//                        }
//                        
//                        // Total Fine
//                        HStack {
//                            Text("Total Fine")
//                                .font(.headline)
//                            Spacer()
//                            Text("$\(String(format: "%.2f", totalFine))")
//                                .font(.title3)
//                                .fontWeight(.bold)
//                                .foregroundColor(.blue)
//                        }
//                        .padding(.top)
//                    }
//                    
//                    // Buttons
//                    VStack(spacing: 12) {
//                        Button(action: applyFine) {
//                            Text("Done")
//                                .fontWeight(.semibold)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(12)
//                        }
//                        
//                        Button(action: { dismiss() }) {
//                            Text("Cancel")
//                                .fontWeight(.medium)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.white)
//                                .foregroundColor(.blue)
//                                .cornerRadius(12)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .stroke(Color.blue, lineWidth: 1)
//                                )
//                        }
//                    }
//                }
//                .padding()
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("Apply Fine")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: { dismiss() }) {
//                        Image(systemName: "chevron.left")
//                            .foregroundColor(.black)
//                    }
//                }
//            }
//        }
//    }
//    
//    func applyFine() {
//        // Implement fine application logic
//        dismiss()
//    }
//} 

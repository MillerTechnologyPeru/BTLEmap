//
//  DecodedAdvertisementView.swift
//  BLE-Scanner
//
//  Created by Alex - SEEMOO on 02.07.20.
//  Copyright © 2020 SEEMOO - TU Darmstadt. All rights reserved.
//

import Foundation
import SwiftUI
import BLETools
import BLEDissector

/// Not used anymore. Kept for reference
struct DecodedAdvertisementView: View {
    var decodedAdv: DecodedAdvType
    @State var opened = false
    
    @State var hoveredRange: ClosedRange<UInt>?
    
    /// Showing the decoded advertisement description with highlighting for the decoded values
    /// - Parameter advDict:Decoded advertisement data
    /// - Returns: SwiftUI View
    func descriptionView(for advDict: [String: AppleBLEDecoding.DecodedEntry]) -> some View {
        
        //Map to tuple of (String, DecodedEntry) and sort it by the bytes
        let advDescription = advDict.map { ($0.0, $0.1) }.sorted { (lhs, rhs) -> Bool in
            if lhs.1.byteRange.lowerBound < rhs.1.byteRange.lowerBound {
                return true
            }
            
            return lhs.1.byteRange.lowerBound == rhs.1.byteRange.lowerBound && lhs.1.description.lowercased() < rhs.1.description.lowercased()
        }
        
        let keyValues: [(String, String)] = advDescription.map({
            (key: String, value: Any) -> (String, String) in
            if let data = value as? Data {
                return (key, (data.hexadecimal.separate(every: 2, with: " ")))
            }
            
            if let array = value as? [Any] {
                return (key, array.map { String(describing: $0) }.joined(separator: ", "))
            }
            
            return (key, String(describing: value))
        })
        
        
        return HStack {
            Text("test")
            //                VStack(alignment: .leading) {
            //                    ForEach(
            //                        0..<keyValues.count,
            //                        content: { idx in
            //                            Text("\(keyValues[idx].0): ")
            //                                .font(.system(.body, design: .monospaced))
            //                                .onTapGesture {
            //                                    self.hoveredRange = advDescription[idx].1.byteRange
            //                                }
            //                        })
            //                }
            //
            //                VStack(alignment: .leading) {
            //                    ForEach(
            //                        0..<keyValues.count,
            //                        content: { idx in
            //                            Text("\(keyValues[idx].1)")
            //                                .font(.system(.body, design: .monospaced))
            //                                .foregroundColor(Color.highlightColor(at: idx))
            //                                .onTapGesture {
            //                                    self.hoveredRange = advDescription[idx].1.byteRange
            //                                }
            //                        })
            //                }
        }
    }
    
    /// Get the highloghtcolor for a byte at index. Used for highlighting raw data
    /// - Parameters:
    ///   - index: The index of the byte in the data
    ///   - advDescription: The advertisement description
    /// - Returns: A color or nil
    func highlightColorForByte(
        at index: UInt, with advDescription: [(String, AppleBLEDecoding.DecodedEntry)]?
    ) -> Color? {
        
        //Get the index of the DecodedEntry to get the color for it
        if let idx = advDescription?.enumerated().first(where: {
            $0.element.1.byteRange.contains(Data.Index(index))
        })?.offset {
            return Color.highlightColor(at: idx)
        }
        
        return nil
    }
    
    /// Shows the raw bytes of the decrypted advertisement. Uses highlighting for visual clues
    /// - Returns: A view that contais the raw data of the advertisement
    func rawDataView(geometry g: GeometryProxy) -> some View {
        //Map to tuple of (String, DecodedEntry) and sort it by the bytes
        //Used to get the color index
        let advDescription = self.decodedAdv.description?.map { ($0.0, $0.1) }.sorted {
            (lhs, rhs) -> Bool in
            return lhs.1.byteRange.lowerBound < rhs.1.byteRange.lowerBound
        }
        
        let byteArray = Array(self.decodedAdv.data)
        
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(0..<byteArray.count) { (idx) in
                Text(String(format: "%02X", byteArray[idx]))
                    .foregroundColor(
                        self.highlightColorForByte(at: UInt(idx), with: advDescription)
                )
                    .background(
                        self.hoveredRange?.contains(UInt(idx)) == true ? Color.gray : nil
                )
                    .padding([.leading, .trailing], 2.0)
                    .alignmentGuide(.leading) { (d) -> CGFloat in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if idx == byteArray.count - 1 {
                            //Last item
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                }
                .alignmentGuide(.top) { (d) -> CGFloat in
                    let result = height
                    if idx == byteArray.count - 1 {
                        height = 0  // last item
                    }
                    
                    return result
                }
            }
        }
    }
    
    var rowTransition: AnyTransition {
        let insertion = AnyTransition.move(edge: .top).combined(with: .opacity)
        let removal = AnyTransition.move(edge: .top).combined(with: .opacity)
        
        return .asymmetric(insertion: insertion, removal: removal)
    }
    
    var body: some View {
        
        AccordeonView(title: Text(decodedAdv.type.description)) {
            VStack {
                GeometryReader { g in
                    self.rawDataView(geometry: g)
                        .frame(width: g.size.width, height: nil, alignment: .topLeading)
                }
                
                if self.decodedAdv.description != nil {
                    HStack {
                        self.descriptionView(for: self.decodedAdv.description!)
                        Spacer()
                    }
                    
                }
            }
        }
    }
}

struct DecodedAdvType: Identifiable {
    var id: UInt
    var type: BLEAdvertisment.AppleAdvertisementType
    var data: Data
    var description: [String: AppleBLEDecoding.DecodedEntry]?
    
    init(
        type: BLEAdvertisment.AppleAdvertisementType, data: Data,
        description: [String: AppleBLEDecoding.DecodedEntry]?
    ) {
        self.type = type
        self.data = data
        self.description = description
        self.id = type.rawValue
    }
}

//
//  ExportedDataFile.swift
//  agile-self
//
//  Transferable wrapper around the exported JSON so it can be shared as a .json file
//  via ShareLink.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct ExportedDataFile: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { file in
            file.data
        }
        .suggestedFileName("AgileSelf-Export.json")
    }
}

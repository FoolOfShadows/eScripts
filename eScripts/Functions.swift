//
//  Functions.swift
//  Chart Parsing
//
//  Created by Fool on 6/17/15.
//  Copyright (c) 2015 Fulgent Wake. All rights reserved.
//

import Cocoa
import Foundation


extension String {
	func findRegexMatchBetween(_ start: String, and end:String) -> String? {
		guard let startRegex = try? NSRegularExpression(pattern: start, options: []) else { return nil }
		guard let endRegex = try? NSRegularExpression(pattern: end, options: []) else {return nil }
		let startMatch = startRegex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
		let endMatch = endRegex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
		
		if !startMatch.isEmpty && !endMatch.isEmpty {
			let startRange = startMatch[0].range
			let endRange = endMatch[0].range
		
			let r = self.index(self.startIndex, offsetBy: startRange.location) ..< self.index(self.startIndex, offsetBy: endRange.location + endRange.length)
		
			return String(self[r])
			//return self.substring(with: r)
		} else {
			return nil
		}
	}
	
	
	func findRegexMatchFrom(_ start: String, to end: String) -> String? {

		guard let startRegex = try? NSRegularExpression(pattern: start, options: []) else { return nil }
		guard let endRegex = try? NSRegularExpression(pattern: end, options: []) else {return nil }
		let startMatch = startRegex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
		let endMatch = endRegex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))

		
		if !startMatch.isEmpty && !endMatch.isEmpty {
			let startRange = startMatch[0].range
			print(startRange)
			let endRange = endMatch[0].range
			print(endRange)

			let r = self.index(self.startIndex, offsetBy: startRange.location + startRange.length) ..< self.index(self.startIndex, offsetBy: endRange.location)
		
			return String(self[r])
		} else {
			return nil
			//return self.substring(with: r)
		}

		
	}
	
	
	func removeWhiteSpace() -> String {
		return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
	}
}

//Get the name, age, and DOB from the text
func nameAgeDOB(_ theText: String?) -> (String, String, String)? {
	var ptName = ""
	var ptPharmacy = ""
	var ptDOB = ""
	guard let theSplitText = theText?.components(separatedBy: "\n") else { return nil }
	
	var lineCount = 0
	if !theSplitText.isEmpty {
		for currentLine in theSplitText {
			switch true {
			case currentLine.range(of: "PRN:") != nil:
				ptName = theSplitText[lineCount - 1]
				lineCount += 1
			case currentLine.range(of: "Gender") != nil && ptName == "":
				ptName = theSplitText[lineCount - 2].replacingOccurrences(of: "Patient", with: "")
				lineCount += 1
			case currentLine.hasPrefix("DOB"):
				let dobLine = currentLine
				ptDOB = simpleRegExMatch(dobLine, theExpression: "\\d./\\d./\\d*")
				lineCount += 1
			case currentLine.hasPrefix("Pharmacy"):
				let pharmacyLine = lineCount + 1
				ptPharmacy = theSplitText[pharmacyLine]
				lineCount += 1
			default:
				lineCount += 1
				continue
			}
//			if currentLine.range(of: "PRN: ") != nil {
//				ptName = theSplitText[lineCount - 1]
//				print(lineCount)
//				continue
//			} else if currentLine.range(of: "Gender") != nil {
//				ptName = theSplitText[lineCount - 2].replacingOccurrences(of: "Patient", with: "")
//			} else if currentLine.hasPrefix("DOB"){
//				let dobLine = currentLine
//				ptDOB = simpleRegExMatch(dobLine, theExpression: "\\d./\\d./\\d*")
//			} else if currentLine.hasPrefix("Pharmacy") {
//				let pharmacyLine = lineCount + 1
//				ptPharmacy = theSplitText[pharmacyLine]
//			}
//			lineCount += 1
		}
	}
	return (ptName, ptPharmacy, ptDOB)
	
}

//Check for the existence of certain strings in the text
//in order to determine the best string to use in the regexTheText function
func defineFinalParameter(_ theText: String, firstParameter: String, secondParameter: String) -> String {
	var theParameter = ""
	if theText.range(of: firstParameter) != nil {
		theParameter = firstParameter
	} else if theText.range(of: secondParameter) != nil {
		theParameter = secondParameter
	}
	return theParameter
}

	
//Clean extraneous text from the sections
func cleanTheSections(_ theSection:String, badBits:[String]) -> String {
	var cleanedText = theSection.removeWhiteSpace()
	for theBit in badBits {
		cleanedText = cleanedText.replacingOccurrences(of: theBit, with: "")
	}
	cleanedText = cleanedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	return cleanedText
}

//A basic regular expression search function
func simpleRegExMatch(_ theText: String, theExpression: String) -> String {
	var theResult = ""
	let regEx = try! NSRegularExpression(pattern: theExpression, options: [])
	let length = theText.characters.count
	
	if let match = regEx.firstMatch(in: theText, options: [], range: NSRange(location: 0, length: length)) {
		theResult = (theText as NSString).substring(with: match.range)
	}
	return theResult
}

func replaceLabelsOf(_ array: inout [String], with subs:[(String, String)]) -> [String] {
	var results = array
	for (position, item) in results.enumerated() {
		for sub in subs {
			if item.contains(sub.0) {
				print(item, sub.0)
				results.remove(at: position)
				let newItem = item.replacingOccurrences(of: sub.0, with: sub.1)
				results.insert(newItem, at: position)
			}
		}
	}
	return results
}

//Parse a string containing a full name into it's components and returns
//the version of the name we use to label files
func getFileLabellingName(_ name: String) -> String {
	var fileLabellingName = String()
	var ptFirstName = ""
	var ptLastName = ""
	var ptMiddleName = ""
	var ptExtraName = ""
	let extraNameBits = ["Sr", "Jr", "II", "III", "IV", "MD"]
	
	func checkForMatchInSets(_ arrayToCheckIn: [String], arrayToCheckFor: [String]) -> Bool {
		var result = false
		for item in arrayToCheckIn {
			if arrayToCheckFor.contains(item) {
				result = true
				break
			}
		}
		return result
	}
	
	let nameComponents = name.components(separatedBy: " ")
	
	let extraBitsCheck = checkForMatchInSets(nameComponents, arrayToCheckFor: extraNameBits)
	
	if extraBitsCheck == true {
		ptLastName = nameComponents[nameComponents.count-2]
		ptExtraName = nameComponents[nameComponents.count-1]
	} else {
		ptLastName = nameComponents[nameComponents.count-1]
		ptExtraName = ""
	}
	
	if nameComponents.count > 2 {
		if nameComponents[nameComponents.count - 2] == "Van" {
			ptLastName = "Van " + ptLastName
		}
	}
	
	//Get first name
	ptFirstName = nameComponents[0]
	
	//Get middle name
	if (nameComponents.count == 3 && extraBitsCheck == true) || nameComponents.count < 3 {
		ptMiddleName = ""
	} else {
		ptMiddleName = nameComponents[1]
	}
	
	fileLabellingName = "\(ptLastName)\(ptFirstName)\(ptMiddleName)\(ptExtraName)"
	fileLabellingName = fileLabellingName.replacingOccurrences(of: " ", with: "")
	fileLabellingName = fileLabellingName.replacingOccurrences(of: "-", with: "")
	fileLabellingName = fileLabellingName.replacingOccurrences(of: "'", with: "")
	fileLabellingName = fileLabellingName.replacingOccurrences(of: "(", with: "")
	fileLabellingName = fileLabellingName.replacingOccurrences(of: ")", with: "")
	fileLabellingName = fileLabellingName.replacingOccurrences(of: "\"", with: "")
	
	
	return fileLabellingName
}

func getScriptDataFrom(_ text:String?) -> String {
	var finalScriptData = "Program failed to find script data."
	if let scriptData = text?.findRegexMatchFrom("Prescribed", to: "GenericsSubstitution") {
		var dataArray:[String] = scriptData.components(separatedBy: "\n")
		dataArray = dataArray.filter {!$0.isEmpty}
		print(dataArray)
		let changedData = replaceLabelsOf(&dataArray, with: replacementSet)
		//print(changedData)
		
		finalScriptData = changedData.joined(separator: "\n")
	}
		
		return finalScriptData
}

func checkPharmacyLocationFrom(_ pharm:String) -> String {
	var result = pharm
	var pharmParts = pharm.components(separatedBy: " ")
	print(pharmParts)
	guard var pharmCode = pharmParts.last else { return result }
	if pharmCode.characters.first == "#" {
		print("Replacing")
		pharmCode = pharmCode.replacingOccurrences(of: "#", with: "")
	}
	if let pharmCode = Int(pharmCode) {
		print(pharmCode)
		if let location = pharmacyCodes[pharmCode] {
			pharmParts.removeLast()
			pharmParts.insert(location, at: pharmParts.endIndex)
			result = pharmParts.joined(separator: " ")
		}
	}
	
	return result
}


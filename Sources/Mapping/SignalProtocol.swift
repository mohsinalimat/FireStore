//
//  SignalProtocol.swift
//  FireStore-iOS
//
//  Created by José Donor on 27/12/2018.
//

import FirebaseFirestore
import ReactiveSwift
import Result
import SwiftXtend



extension SignalProtocol where Value == DocumentSnapshot?, Error == NSError {

	public func mapData() -> Signal<[String: Any]?, Error> {

		return signal.map { $0?.data() }
	}

	public func map<T: Identifiable & Decodable>(_ type: T.Type)
		-> Signal<T?, Error> where T.Identifier == String {

			return signal
				.attemptMap { document -> Result<T?, Error> in

					guard
						let document = document,
						document.exists
						else { return .success(nil) }


					do {
						let data = try JSONSerialization.data(withJSONObject: document.data() as Any)

						let decoder = JSONDecoder()
						decoder.dateDecodingStrategy = .millisecondsSince1970

						var value = try decoder.decode(type, from: data)
						value.id = document.documentID

						return .success(value)
					}
					catch let error as NSError {
						return .failure(error)
					}

				}
	}

	public func mapWithMetadata<T: Identifiable & Decodable>(_ type: T.Type)
		-> Signal<(value: T, metadata: SnapshotMetadata)?, Error> where T.Identifier == String {

			return signal
				.attemptMap { document -> Result<(value: T, metadata: SnapshotMetadata)?, Error> in

					guard
						let document = document,
						document.exists
						else { return .success(nil) }


					do {
						let data = try JSONSerialization.data(withJSONObject: document.data() as Any)

						let decoder = JSONDecoder()
						decoder.dateDecodingStrategy = .millisecondsSince1970

						var value = try decoder.decode(type, from: data)
						value.id = document.documentID

						let metadata = document.metadata

						return .success((value, metadata))
					}
					catch let error as NSError {
						return .failure(error)
					}

				}
	}

}


extension SignalProtocol where Value == QuerySnapshot, Error == NSError {

	public func mapData() -> Signal<[String: [String: Any]], Error> {

		return signal
			.map { query in

				let documents = query.documents
				let keysAndData = documents.map { ($0.documentID, $0.data()) }

				return .init(uniqueKeysWithValues: keysAndData)
			}
	}

	public func mapArray<T: Identifiable & Decodable>(of type: T.Type)
		-> Signal<[T], Error> where T.Identifier == String {

			return signal
				.attemptMap { query -> Result<[T], Error> in

					var values = [T]()

					let documents = query.documents

					values.reserveCapacity(documents.count)

					for document in documents {
						do {
							let data = try JSONSerialization.data(withJSONObject: document.data())

							let decoder = JSONDecoder()
							decoder.dateDecodingStrategy = .millisecondsSince1970

							var value = try decoder.decode(type, from: data)
							value.id = document.documentID

							values.append(value)
						}
						catch let error as NSError {
							return .failure(error)
						}
					}

					return .success(values)
				}
	}

	public func mapArrayWithMetadata<T: Identifiable & Decodable>(of type: T.Type)
		-> Signal<(values: [T], metadatas: [SnapshotMetadata], queryMetadata: SnapshotMetadata), Error> where T.Identifier == String {

			return signal
				.attemptMap { query -> Result<(values: [T], metadatas: [SnapshotMetadata], queryMetadata: SnapshotMetadata), Error> in

					var values = [T]()
					var metadatas = [SnapshotMetadata]()

					let documents = query.documents
					let count = documents.count

					values.reserveCapacity(count)
					metadatas.reserveCapacity(count)

					for document in documents {
						do {
							let data = try JSONSerialization.data(withJSONObject: document.data())

							let decoder = JSONDecoder()
							decoder.dateDecodingStrategy = .millisecondsSince1970

							var value = try decoder.decode(type, from: data)
							value.id = document.documentID

							let metadata = document.metadata

							values.append(value)
							metadatas.append(metadata)
						}
						catch let error as NSError {
							return .failure(error)
						}
					}

					let metadata = query.metadata

					return .success((values, metadatas, metadata))
				}
	}

	public func mapChanges<T: Identifiable & Decodable>(of type: T.Type)
		-> Signal<[Change<T>], Error> where T.Identifier == String {

			return signal
				.attemptMap { query -> Result<[Change<T>], Error> in

					var changes = [Change<T>]()

					let documentChanges = query.documentChanges(includeMetadataChanges: false)

					changes.reserveCapacity(documentChanges.count)

					for documentChange in documentChanges {
						do {
							let change = try Change(change: documentChange, ofType: type)
							changes.append(change)
						}
						catch let error as NSError {
							return .failure(error)
						}
					}

					return .success(changes)
				}
	}

}

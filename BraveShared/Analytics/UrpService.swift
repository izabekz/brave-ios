/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SafariServices
import Shared

private let log = Logger.browserLogger

enum UrpError {
    case networkError, downloadIdNotFound, ipNotFound, endpointError
}

/// Api endpoints for user referral program.
struct UrpService {
    private static let apiKeyParam = "api_key"
    private static let downLoadIdKeyParam = "download_id"

    let host: String
    private let apiKey: String
    let sessionManager: URLSession
    private let certificateEvaluator: PinningCertificateEvaluator

    init?(host: String, apiKey: String) {
        self.host = host
        self.apiKey = apiKey

        guard let hostUrl = URL(string: host), let normalizedHost = hostUrl.normalizedHost() else { return nil }

        // Certificate pinning
        certificateEvaluator = PinningCertificateEvaluator(hosts: [normalizedHost])
        
        sessionManager = URLSession(configuration: .default, delegate: certificateEvaluator, delegateQueue: .main)
    }

    func referralCodeLookup(completion: @escaping (ReferralData?, UrpError?) -> Void) {
        guard var endPoint = URL(string: host) else {
            completion(nil, .endpointError)
            UrpLog.log("Host not a url: \(host)")
            return
        }
        endPoint.appendPathComponent("promo/initialize/ua")

        let params = [UrpService.apiKeyParam: apiKey]

        sessionManager.urpApiRequest(endPoint: endPoint, params: params) { response in
            switch response {
            case .success(let data):
                log.debug("Referral code lookup response: \(data)")
                UrpLog.log("Referral code lookup response: \(data)")
                
                do {
                    let referral = try JSONDecoder().decode(ReferralData.self, from: data)
                    completion(referral, nil)
                } catch {
                    log.error("Unable to deserialize ReferralData from json: \(error)")
                    UrpLog.log("Error: Unable to deserialize ReferralData from json: \(error)")
                    
                    completion(nil, .endpointError)
                }
                
            case .failure(let error):
                log.error("Referral code lookup response: \(error)")
                UrpLog.log("Referral code lookup response: \(error)")
                
                completion(nil, .endpointError)
            }
        }
    }
    
    func checkIfAuthorizedForGrant(with downloadId: String, completion: @escaping (Bool?, UrpError?) -> Void) {
        guard var endPoint = URL(string: host) else {
            completion(nil, .endpointError)
            return
        }
        endPoint.appendPathComponent("promo/activity")

        let params = [
            UrpService.apiKeyParam: apiKey,
            UrpService.downLoadIdKeyParam: downloadId
        ]

        sessionManager.urpApiRequest(endPoint: endPoint, params: params) { response in
            switch response {
            case .success(let data):
                log.debug("Check if authorized for grant response: \(data)")
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any]
                    
                    completion(json?["finalized"] as? Bool ?? false, nil)
                } catch {
                    log.error("Check if authorized for grant response: \(error)")
                    completion(nil, .endpointError)
                }
                
            case .failure(let error):
                log.error("Check if authorized for grant response: \(error)")
                completion(nil, .endpointError)
            }
        }
    }

    func fetchCustomHeaders(completion: @escaping ([CustomHeaderData], UrpError?) -> Void) {
        guard var endPoint = URL(string: host) else {
            completion([], .endpointError)
            return
        }
        endPoint.appendPathComponent("promo/custom-headers")

        let params = [UrpService.apiKeyParam: apiKey]

        sessionManager.request(endPoint, parameters: params) { response in
            switch response {
            case .success(let data):
                let customHeaders = CustomHeaderData.customHeaders(from: data)
                completion(customHeaders, nil)
            case .failure(let error):
                log.error(error)
                completion([], .endpointError)
            }
        }
    }
}

extension URLSession {
    /// All requests to referral api use PUT method, accept and receive json.
    func urpApiRequest(endPoint: URL, params: [String: String], completion: @escaping (Result<Data, Error>) -> Void) {
        
        self.request(endPoint, method: .put, parameters: params, encoding: .json) { response in
            completion(response)
        }
    }
}

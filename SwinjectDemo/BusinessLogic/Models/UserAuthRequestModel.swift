//
//  UserAuthRequestModel.swift
//  SwinjectDemo
//
//  Created by user on 19.01.2022.
//

import Foundation

struct UserAuthRequestModel: Encodable {
    let email: String
    let password: String
}

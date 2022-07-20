//
//  CharactersService.swift
//  SwinjectDemo
//
//  Created by user on 24.01.2022.
//

import Foundation
import CombineNetworking
import Combine

protocol CharactersService {
    func getCharacters() -> AnyPublisher<[CharacterModel], CNError>
}

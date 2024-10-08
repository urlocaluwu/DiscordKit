//
//  CachedState.swift
//  DiscordAPI
//
//  Created by Vincent Kwok on 22/2/22.
//

import Foundation
import DiscordKitCore

/// A struct for storing cached data from the Gateway
///
/// Used in ``DiscordGateway/cache``.
public class CachedState: ObservableObject {
    /// Dictionary of guilds the user is in
    ///
    /// > The guild's ID is its key
    @Published public private(set) var guilds: [Snowflake: PreloadedGuild] = [:]

    @Published public private(set) var members: [Snowflake: Member] = [:]

    /// DM channels the user is in
    @Published public private(set) var dms: [Channel] = []

    /// Cached object of current user
    @Published public private(set) var user: CurrentUser?

    /// Cached users, initially populated from `READY` event and might
    /// grow over time
    @Published public private(set) var users: [Snowflake: User] = [:]

    /// Populates the cache using the provided event.
    /// - Parameter event: An incoming Gateway "ready" event.

    func configure(using event: ReadyEvt) {
    // Unwrap the guilds
    event.guilds.forEach { decodeResult in
        if let guild = try? decodeResult.unwrap() {
            appendOrReplace(guild)
        } else {
            print("Failed to decode guild")
        }
    }

    // Unwrap DM channels
    dms = event.private_channels.compactUnwrap()

    // Unwrap users
    event.users.forEach { decodeResult in
        if let user = try? decodeResult.unwrap() {
            appendOrReplace(user)
        } else {
            print("Failed to decode user")
        }
    }

    // Handle members and current user
    user = event.user
    event.merged_members.enumerated().forEach { (idx, guildMembers) in
        if let guildID = try? event.guilds[idx].unwrap().id {
            members[guildID] = guildMembers.first(where: { $0.user_id == event.user.id })
        }
    }
}


    // MARK: - Guilds

    /// Updates or appends the provided guild.
    /// - Parameter guild: The guild you want to update or append to the cache.
    func appendOrReplace(_ decodeResult: DecodeThrowable<PreloadedGuild>) {
        if let guild = try? decodeResult.unwrap() {
            guilds.updateValue(guild, forKey: guild.id)
        } else {
            print("Failed to decode guild")
        }
    }


    /// Removes any guilds with an identifier matching the identifier of the provided guild parameter.
    /// - Parameter guild: A ``Guild`` instance whose identifier will be used to remove any guilds with a matching identifier.
    func remove(_ guild: GuildUnavailable) {
        guilds.removeValue(forKey: guild.id)
    }

    // MARK: - Channels

    /// Appends the provided channel to the appropriate cached guild.
    /// - Parameter channel: The channel to append.
    func append(_ channel: Channel) {
        guard let identifier = channel.guild_id else {
            return
        }

        // guilds[identifier]?.channels?.append(channel)
    }

    /// Removes the provided channel from the appropriate cached guild.
    /// - Parameter channel: The channel to remove.
    func remove(_ channel: Channel) {
        guard let identifier = channel.guild_id else {
            return
        }

        // guilds[

        // guilds[identifier]?.channels?.removeAll(matchingIdentifierFor: channel)
    }

    /// Replaces the first channel with an identifier that matches the provided channel's identifier..
    /// - Parameter channel: The channel to replace
    func replace(_ channel: Channel) {
        /*guard
            let guildID = channel.guild_id,
            let channelIndex = guilds[guildID]?
                .channels?
                .firstIndex(matchingIdentifierFor: channel)
        else {
            return
        }

        guilds[guildID]?.channels?[channelIndex] = channel*/
    }

    // MARK: - Messages

    /// Appends or replaces  the given message within the appropriate channel.
    /// - Parameter message: The message to append.
    func appendOrReplace(_ message: Message) {
        if let idx = dms.firstIndex(where: { $0.id == message.channel_id }) {
            dms[idx].last_message_id = message.id
        }
    }

    // MARK: - Users

    /// Appends or replaces the provided user in the cache.
    /// - Parameter user: The user to cache.
    func appendOrReplace(_ user: User) {
        users.updateValue(user, forKey: user.id)
    }

    /// Replaces the current user with the provided one
    func replace(_ user: CurrentUser) {
        self.user = user
    }
}

extends Node

const Config = preload("res://scripts/config.gd")
const HeadlessServer = preload("res://scripts/server.gd")
const HeadlessClient = preload("res://scripts/headless_client.gd")
const Client = preload("res://scripts/client.gd")


func _ready() -> void:
    var config: Config = Config.new()
    var server: HeadlessServer = HeadlessServer.new()
    var clients: Array[Client] = []
    clients.resize(config.player_count)
    for index in range(config.player_count):
        var client: HeadlessClient = HeadlessClient.new(server, index)
        clients[index] = client
    var match = server.create_match(config, clients)
    match.start_game()

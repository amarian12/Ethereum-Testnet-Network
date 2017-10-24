#!/usr/bin/env ruby

require "bundler/setup"
require 'json-rpc-client'
require 'json'

TIMER = 3

EM.run {
  EventMachine.add_periodic_timer(TIMER) {
    account = ARGV[0]
    unless account
      puts "Please set address to check balance"
      exit 1
    end

    eth_node = JsonRpcClient.new('http://localhost:8545/') 
    response = eth_node.eth_getBalance(account, "latest")

    response.callback do |result|
      if !Integer(result).zero?
        wei = Integer("1" + "0" * 18) # 1 Ether 10^18 Wei
        balance = (Integer(result) / wei).to_f
        puts "Address: #{account} balance: #{Integer(balance)}"
      else
        puts "Address: #{account} balance: #{Integer(result)}"
      end
    end

    response.errback do |error|
      puts error
    end
    puts "Sleep #{TIMER} second ..."
  }
}

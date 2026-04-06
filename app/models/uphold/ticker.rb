module Uphold
  # Simple model that validates and normalizes Uphold ticker responses.
  class Ticker
    attr_reader :pair, :ask, :bid

    def initialize(pair:, ask:, bid:)
      @pair = pair.to_s
      @ask = Float(ask)
      @bid = Float(bid)
    end

    def self.from_api(pair, data)
      raise ArgumentError, 'Resposta do ticker inválida' unless data.is_a?(Hash)
      raise ArgumentError, 'Resposta do ticker sem ask' if data['ask'].nil?
      raise ArgumentError, 'Resposta do ticker sem bid' if data['bid'].nil?

      new(pair: pair, ask: data['ask'], bid: data['bid'])
    end

    def spread
      ask - bid
    end

    def to_h
      {
        symbol: pair,
        ask: format_value(ask),
        bid: format_value(bid),
        spread: format_value(spread)
      }
    end

    private

    def format_value(value)
      sprintf('%.8f', value).sub(/\.?(0+)$/, '')
    end
  end
end

module Uphold
  # Model that represents one comparison row for an asset pair.
  class ComparisonResult
    attr_reader :pair, :ask, :bid, :error

    def initialize(pair:, ask: nil, bid: nil, error: nil)
      @pair = pair.to_s
      @ask = ask.nil? ? nil : Float(ask)
      @bid = bid.nil? ? nil : Float(bid)
      @error = error
    end

    def self.from_api(pair, data)
      raise ArgumentError, 'Dados da comparação inválidos' unless data.is_a?(Hash)
      raise ArgumentError, 'Resposta de comparação sem ask' if data['ask'].nil?
      raise ArgumentError, 'Resposta de comparação sem bid' if data['bid'].nil?

      new(pair: pair, ask: data['ask'], bid: data['bid'])
    end

    def self.error(pair, message)
      new(pair: pair, error: message)
    end

    def spread
      return nil if ask.nil? || bid.nil?

      ask - bid
    end

    def to_h
      {
        pair: pair,
        ask: ask.nil? ? nil : format_value(ask),
        bid: bid.nil? ? nil : format_value(bid),
        spread: spread.nil? ? nil : format_value(spread),
        error: error
      }
    end

    private

    def format_value(value)
      sprintf('%.8f', value).sub(/\.?(0+)$/, '')
    end
  end
end

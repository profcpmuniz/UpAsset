module Uphold
  # Simple model for Uphold assets, used to normalize the asset list.
  class Asset
    attr_reader :symbol, :name, :currency

    def initialize(symbol:, name:, currency: nil)
      @symbol = symbol.to_s
      @name = name.to_s
      @currency = currency.nil? ? nil : currency.to_s
    end

    def self.from_api(data)
      raise ArgumentError, 'Resposta de asset inválida' unless data.is_a?(Hash)

      identifier = data['symbol'] || data['code'] || data['shortName']
      raise ArgumentError, 'Asset sem código ou símbolo' if identifier.nil?
      raise ArgumentError, 'Asset sem nome' if data['name'].nil?

      new(symbol: identifier, name: data['name'], currency: data['currency'])
    end

    def to_h
      {
        symbol: symbol,
        name: name,
        currency: currency
      }
    end
  end
end

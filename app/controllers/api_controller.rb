require 'net/http'
require 'uri'

class ApiController < ApplicationController
  BASE_URL = 'https://api.uphold.com/v0'.freeze
  REQUEST_TIMEOUT = 10

  # Proxy request for the Uphold ticker endpoint.
  # This avoids CORS issues by keeping the browser request on the Rails server.
  def ticker
    pair = params[:pair].to_s.upcase.strip
    raw_response = fetch_uphold("/ticker/#{URI.encode_www_form_component(pair)}")
    ticker = Uphold::Ticker.from_api(pair, raw_response)

    render json: ticker.to_h
  rescue StandardError => e
    render_error(e)
  end

  # Proxy request for the Uphold assets endpoint.
  def assets
    raw_assets = fetch_uphold('/assets')
    assets = Array(raw_assets).map do |item|
      Uphold::Asset.from_api(item).to_h
    end

    render json: assets
  rescue StandardError => e
    render_error(e)
  end

  # Compare the same asset in multiple fiat currencies.
  # Returns USD, EUR, GBP and CHF quotes in one payload.
  def compare
    asset = params[:asset].to_s.upcase.strip
    raise StandardError, 'Asset inválido' if asset.empty?

    currencies = %w[USD EUR GBP CHF]
    comparisons = currencies.map do |currency|
      pair = "#{asset}-#{currency}"

      begin
        raw_response = fetch_uphold("/ticker/#{URI.encode_www_form_component(pair)}")
        Uphold::ComparisonResult.from_api(pair, raw_response)
      rescue StandardError => e
        Uphold::ComparisonResult.error(pair, e.message)
      end
    end

    render json: Uphold::CompareResponse.new(asset: asset, comparisons: comparisons).to_h
  rescue StandardError => e
    render_error(e)
  end

  private

  def fetch_uphold(path)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = REQUEST_TIMEOUT
    http.read_timeout = REQUEST_TIMEOUT

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    parsed_body = parse_json(response.body)
    return parsed_body if response.is_a?(Net::HTTPSuccess)

    error_message = parsed_body.is_a?(Hash) ? parsed_body['message'] : response.message
    raise StandardError, "Uphold API error: #{error_message || response.code}"
  end

  def parse_json(body)
    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end

  def render_error(exception)
    logger.error("[Uphold Explorer] #{exception.class}: #{exception.message}")
    render json: { error: "Não foi possível carregar os dados. #{exception.message}" }, status: :bad_gateway
  end
end

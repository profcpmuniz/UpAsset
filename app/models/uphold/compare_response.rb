module Uphold
  # Model that aggregates comparison results for a single asset.
  class CompareResponse
    attr_reader :asset, :comparisons

    def initialize(asset:, comparisons:)
      @asset = asset.to_s
      @comparisons = comparisons
    end

    def to_h
      {
        asset: asset,
        comparisons: comparisons.map { |comparison| comparison.to_h }
      }
    end
  end
end

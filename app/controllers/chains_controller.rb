# frozen_string_literal: true

class ChainsController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q].to_s.strip
    @tier_filter = params[:tier].presence_in(%w[ all full docs_only ]) || "all"
    @page_scope = params[:scope].presence_in(%w[ chains testnets ]) || "chains"
    @network_filter = params[:network].presence_in(%w[ all mainnet testnet ]) || (@page_scope == "testnets" ? "testnet" : "all")

    @chains = Chains::Catalog.all.select { |chain| chain_visible?(chain) }
    @full_chains = @chains.select(&:full?)
    @docs_only_chains = @chains.select(&:docs_only?)
    @mainnet_chains = @chains.select(&:mainnet?)
    @testnet_chains = @chains.select(&:testnet?)
    @contract_total = @chains.sum(&:contract_count)
    @top_kinds = @chains.each_with_object(Hash.new(0)) do |chain, counts|
      chain.kind_counts.each do |kind, count|
        counts[kind] += count
      end
    end.sort_by { |kind, count| [ -count, kind ] }.first(4)
    response.set_header("Vary", "Accept-Language, Cookie")
    expires_in 12.hours, public: true
  end

  def show
    @chain = Chains::Catalog.fetch(params[:slug])
    response.set_header("Vary", "Accept-Language, Cookie")
    expires_in 12.hours, public: true
    respond_to do |format|
      format.html
      format.md { render :show, formats: :md, content_type: "text/markdown" }
    end
  rescue KeyError
    raise ActiveRecord::RecordNotFound, "unknown chain: #{params[:slug]}"
  end

  private

  def chain_visible?(chain)
    tier_matches = @tier_filter == "all" || chain.tier.to_s == @tier_filter
    network_matches = @network_filter == "all" || chain.network_kind.to_s == @network_filter
    return false unless tier_matches && network_matches
    return true if @query.blank?

    haystack = [
      chain.slug,
      chain.name,
      chain.summary,
      chain.docs_url,
      *chain.contracts.map(&:name),
      *chain.contracts.map(&:slug),
      *chain.contracts.map(&:address),
      *chain.contracts.map(&:kind)
    ].compact.join(" ").downcase

    haystack.include?(@query.downcase)
  end
end

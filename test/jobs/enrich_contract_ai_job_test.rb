require "test_helper"

class EnrichContractAiJobTest < ActiveJob::TestCase
  setup do
    @contract = contracts(:uni_token)
  end

  test "stores AI natspec and broadcasts a turbo refresh" do
    enriched = { "functions" => { "transfer" => { "notice" => "Transfers tokens." } } }

    broadcasts = []
    stub_class_method(ContractDocument::AiEnricher, :call, ->(_c) { enriched }) do
      stub_class_method(Turbo::StreamsChannel, :broadcast_refresh_to, ->(*targets, **_) {
        broadcasts << targets
      }) do
        EnrichContractAiJob.perform_now(@contract)
      end
    end

    assert_equal enriched, @contract.reload.ai_natspec
    assert_equal 1, broadcasts.size
    assert_equal @contract, broadcasts.first.first
  end

  test "skips persist and broadcast when enricher returns no functions" do
    empty = { "functions" => {} }

    broadcasts = []
    stub_class_method(ContractDocument::AiEnricher, :call, ->(_c) { empty }) do
      stub_class_method(Turbo::StreamsChannel, :broadcast_refresh_to, ->(*t, **_) { broadcasts << t }) do
        EnrichContractAiJob.perform_now(@contract)
      end
    end

    assert_nil @contract.reload.ai_natspec
    assert_empty broadcasts
  end
end

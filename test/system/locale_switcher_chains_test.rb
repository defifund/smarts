require "application_system_test_case"

class LocaleSwitcherChainsTest < ApplicationSystemTestCase
  test "switching locale on the chains page keeps the chains route localized" do
    visit "/chains"

    assert_text "Supported chains"

    click_button "EN"
    click_button "简体中文"

    assert_current_path "/cn/chains", ignore_query: true
    assert_text "支持的链"
  end
end

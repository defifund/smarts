module ContractsHelper
  # Dispatches by ABI output shape: tuples → (name: val, ...), arrays → [...],
  # scalars → format_abi_value. Prefer this over format_abi_value when you have
  # the full output hash (with components for tuples).
  def format_abi_output(value, output)
    type = output["type"].to_s
    if type == "tuple"
      format_tuple(value, Array(output["components"]))
    elsif type.start_with?("tuple[")
      suffix = type.sub(/\Atuple/, "")
      if suffix == "[]"
        "[" + Array(value).map { |v| format_tuple(v, Array(output["components"])) }.join(", ") + "]"
      else
        # Fixed-size tuple array like tuple[2]: treat as array of tuples
        "[" + Array(value).map { |v| format_tuple(v, Array(output["components"])) }.join(", ") + "]"
      end
    else
      format_abi_value(value, type)
    end
  end

  # Format a single decoded ABI value for inline display.
  # Types handled: uint/int*, bool, address, string, bytes*, arrays (shallow).
  def format_abi_value(value, type)
    case type
    when /\A(u?int)(\d*)\z/
      format_integer(value)
    when "bool"
      value ? "true" : "false"
    when "address"
      value.to_s.downcase
    when "string"
      value.to_s.length > 80 ? "#{value.to_s[0, 77]}..." : value.to_s
    when /\Abytes\d+\z/, "bytes"
      "0x" + value.to_s.unpack1("H*")
    when /\A(.+)\[\]\z/
      inner = $1
      "[" + Array(value).map { |v| format_abi_value(v, inner) }.join(", ") + "]"
    else
      value.inspect
    end
  end

  # Given a Multicall3Client::Result + ABI function hash, return an inline HTML-safe
  # string ready to drop next to the function name. Returns nil if there's nothing useful.
  def render_live_result(result, fn)
    return nil unless result

    if !result.success
      return content_tag(:span, "reverted", class: "text-error text-xs font-mono")
    end

    outputs = Array(fn["outputs"])
    return nil if outputs.empty? || result.values.empty?

    parts = result.values.each_with_index.map do |v, i|
      format_abi_output(v, outputs[i])
    end

    content_tag(:span, "→ #{parts.join(', ')}", class: "text-success text-xs font-mono break-all")
  end

  # Builds a human-readable signature with named parameters:
  # balanceOf(account: address)  —  omits names when unnamed.
  def function_signature_with_params(fn)
    inputs = Array(fn["inputs"])
    return "#{fn['name']}()" if inputs.empty?

    parts = inputs.map do |i|
      name = i["name"].to_s
      name.empty? ? i["type"] : "#{name}: #{i['type']}"
    end

    "#{fn['name']}(#{parts.join(', ')})"
  end

  private

  def format_integer(n)
    return n.to_s unless n.is_a?(Integer)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
  end

  def format_tuple(value, components)
    parts = components.each_with_index.map do |comp, i|
      v = Array(value)[i]
      rendered = format_abi_output(v, comp)
      name = comp["name"].to_s
      name.empty? ? rendered : "#{name}: #{rendered}"
    end
    "(#{parts.join(', ')})"
  end
end

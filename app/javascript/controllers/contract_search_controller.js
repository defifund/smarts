import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chainSelect", "addressInput"]

  submit(event) {
    event.preventDefault()
    const chain = this.chainSelectTarget.value
    const address = this.addressInputTarget.value

    if (!address.match(/^0x[0-9a-fA-F]{40}$/)) {
      this.addressInputTarget.focus()
      return
    }

    window.location.href = `/?q=${chain}/${address}`
  }
}

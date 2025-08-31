import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nickname", "registerButton", "status", "successMessage", "errorMessage", "successText", "errorText"]

  connect() {
    // Check if WebAuthn is supported
    if (!window.PublicKeyCredential) {
      this.showError("WebAuthn is not supported in this browser. Please use a modern browser that supports passkeys.")
      this.registerButtonTarget.disabled = true
      return
    }
  }

  async register(event) {
    event.preventDefault()
    
    this.hideMessages()
    this.registerButtonTarget.disabled = true
    this.registerButtonTarget.textContent = "Creating passkey..."

    try {
      // Get registration options from server
      const response = await fetch('/users/passkey_management/new', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })

      if (!response.ok) {
        throw new Error('Failed to get registration options')
      }

      const options = await response.json()
      console.log('Registration options:', options)

      // Convert base64url to ArrayBuffer with safety checks
      if (options.challenge && typeof options.challenge === 'string') {
        options.challenge = this.base64urlToArrayBuffer(options.challenge)
      } else {
        console.error('Invalid challenge format:', options.challenge)
        throw new Error('Invalid challenge format received from server')
      }

      if (options.user && options.user.id && typeof options.user.id === 'string') {
        options.user.id = this.base64urlToArrayBuffer(options.user.id)
      } else {
        console.error('Invalid user ID format:', options.user?.id)
        throw new Error('Invalid user ID format received from server')
      }

      // Create the credential
      const credential = await navigator.credentials.create({
        publicKey: options
      })

      // Convert ArrayBuffer to base64url
      const publicKeyCredential = {
        id: credential.id,
        type: credential.type,
        rawId: this.arrayBufferToBase64url(credential.rawId),
        response: {
          clientDataJSON: this.arrayBufferToBase64url(credential.response.clientDataJSON),
          attestationObject: this.arrayBufferToBase64url(credential.response.attestationObject)
        }
      }

      // Send to server for verification
      const createResponse = await fetch('/users/passkey_management', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({
          credential: publicKeyCredential,
          nickname: this.nicknameTarget.value
        })
      })

      const result = await createResponse.json()

      if (createResponse.ok) {
        this.showSuccess(`Passkey "${result.credential.nickname}" was successfully created!`)
        this.nicknameTarget.value = ''
        // Reload the page to show the new passkey
        setTimeout(() => {
          window.location.reload()
        }, 2000)
      } else {
        throw new Error(result.error || 'Failed to create passkey')
      }

    } catch (error) {
      console.error('Passkey registration error:', error)
      this.showError(error.message || 'Failed to create passkey. Please try again.')
    } finally {
      this.registerButtonTarget.disabled = false
      this.registerButtonTarget.innerHTML = `
        <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
        </svg>
        Add Passkey
      `
    }
  }

  showSuccess(message) {
    this.successTextTarget.textContent = message
    this.statusTarget.classList.remove('hidden')
    this.successMessageTarget.classList.remove('hidden')
    this.errorMessageTarget.classList.add('hidden')
  }

  showError(message) {
    this.errorTextTarget.textContent = message
    this.statusTarget.classList.remove('hidden')
    this.errorMessageTarget.classList.remove('hidden')
    this.successMessageTarget.classList.add('hidden')
  }

  hideMessages() {
    this.statusTarget.classList.add('hidden')
    this.successMessageTarget.classList.add('hidden')
    this.errorMessageTarget.classList.add('hidden')
  }

  // Utility functions for base64url conversion
  base64urlToArrayBuffer(base64url) {
    if (typeof base64url !== 'string') {
      throw new Error(`Expected string for base64url conversion, got ${typeof base64url}`)
    }
    
    const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/')
    const padding = '='.repeat((4 - base64.length % 4) % 4)
    const base64Padded = base64 + padding
    const binaryString = atob(base64Padded)
    const bytes = new Uint8Array(binaryString.length)
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i)
    }
    return bytes.buffer
  }

  arrayBufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer)
    const binaryString = String.fromCharCode.apply(null, bytes)
    const base64 = btoa(binaryString)
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
  }
}

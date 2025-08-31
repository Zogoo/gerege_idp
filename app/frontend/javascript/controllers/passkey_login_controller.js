import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "submitButton", "status", "successMessage", "errorMessage", "successText", "errorText", "passwordForm", "passkeyForm"]

  connect() {
    console.log('PasskeyLoginController connected')
    console.log('Targets found:', {
      passkeyForm: this.hasPasskeyFormTarget,
      passwordForm: this.hasPasswordFormTarget,
      email: this.hasEmailTarget,
      submitButton: this.hasSubmitButtonTarget
    })
    
    // Check if WebAuthn is supported
    if (!window.PublicKeyCredential) {
      this.showError("WebAuthn is not supported in this browser. Please use a modern browser that supports passkeys.")
      this.submitButtonTarget.disabled = true
      return
    }
  }

  async initiateLogin(event) {
    event.preventDefault()
    
    this.hideMessages()
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.textContent = "Authenticating..."

    try {
      const email = this.emailTarget.value.trim()
      
      if (!email) {
        throw new Error('Please enter your email address')
      }

      // Get authentication options from server
      const response = await fetch('/users/passkey_login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({ email: email })
      })

      const result = await response.json()

      if (!response.ok) {
        // Check if it's a "no passkeys" error
        if (result.error && result.error.includes('Invalid username or passkey')) {
          this.showError(result.error)
          // Show password form as fallback
          setTimeout(() => {
            this.showPasswordForm()
          }, 3000)
        } else {
          throw new Error(result.error || 'Failed to get authentication options')
        }
        return
      }

      const options = result

      // Convert base64url to ArrayBuffer
      options.challenge = this.base64urlToArrayBuffer(options.challenge)
      options.allowCredentials = options.allowCredentials.map(credential => ({
        ...credential,
        id: this.base64urlToArrayBuffer(credential.id)
      }))

      // Get the credential
      const assertion = await navigator.credentials.get({
        publicKey: options
      })

      // Convert ArrayBuffer to base64url
      const publicKeyCredential = {
        id: assertion.id,
        type: assertion.type,
        rawId: this.arrayBufferToBase64url(assertion.rawId),
        response: {
          clientDataJSON: this.arrayBufferToBase64url(assertion.response.clientDataJSON),
          authenticatorData: this.arrayBufferToBase64url(assertion.response.authenticatorData),
          signature: this.arrayBufferToBase64url(assertion.response.signature),
          userHandle: assertion.response.userHandle ? this.arrayBufferToBase64url(assertion.response.userHandle) : null
        }
      }

      // Send to server for verification
      const authenticateResponse = await fetch('/users/passkey_login/authenticate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({
          credential: publicKeyCredential
        })
      })

      const authResult = await authenticateResponse.json()

      if (authenticateResponse.ok) {
        this.showSuccess('Authentication successful! Redirecting...')
        // Redirect to the specified URL
        setTimeout(() => {
          window.location.href = authResult.redirect_url
        }, 1000)
      } else {
        throw new Error(authResult.error || 'Authentication failed')
      }

    } catch (error) {
      console.error('Passkey authentication error:', error)
      this.showError(error.message || 'Authentication failed. Please try again.')
    } finally {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.innerHTML = `
        <svg class="mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
        </svg>
        Continue with Passkey
      `
    }
  }

  showPasswordForm() {
    this.passkeyFormTarget.classList.add('hidden')
    this.passwordFormTarget.classList.remove('hidden')
  }

  showPasskeyForm() {
    this.passwordFormTarget.classList.add('hidden')
    this.passkeyFormTarget.classList.remove('hidden')
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

/**
 * Divider tool for EditorJS
 * Creates a visual divider/separator between content blocks
 */

export class Divider {
  static get toolbox() {
    return {
      title: 'Divider',
      icon: `<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="3" y1="12" x2="21" y2="12"></line>
        <line x1="3" y1="6" x2="21" y2="6"></line>
        <line x1="3" y1="18" x2="21" y2="18"></line>
      </svg>`
    }
  }

  static get isReadOnlySupported() {
    return true
  }

  constructor({ data, config, api, readOnly }) {
    this.api = api
    this.config = config || {}
    this.data = data || {}
    this.readOnly = readOnly

    this.CSS = {
      wrapper: 'divider-tool-wrapper',
      divider: 'divider-tool',
      select: 'divider-tool-select'
    }
  }

  render() {
    const wrapper = document.createElement('div')
    wrapper.className = this.CSS.wrapper

    if (!this.readOnly) {
      // In edit mode, show a select dropdown for divider style
      const select = document.createElement('select')
      select.className = this.CSS.select
      select.style.cssText = `
        width: 200px;
        padding: 8px;
        border: 1px solid #e2e8f0;
        border-radius: 6px;
        background: white;
        font-size: 14px;
      `

      const styles = [
        { value: 'solid', label: 'Solid Line' },
        { value: 'dashed', label: 'Dashed Line' },
        { value: 'dotted', label: 'Dotted Line' },
        { value: 'double', label: 'Double Line' },
        { value: 'thick', label: 'Thick Line' },
        { value: 'fade', label: 'Fade Effect' }
      ]

      styles.forEach(style => {
        const option = document.createElement('option')
        option.value = style.value
        option.textContent = style.label
        option.selected = this.data.style === style.value
        select.appendChild(option)
      })

      select.addEventListener('change', (e) => {
        this.data.style = e.target.value
        this.updatePreview(wrapper)
      })

      wrapper.appendChild(select)
    }

    this.updatePreview(wrapper)
    return wrapper
  }

  updatePreview(wrapper) {
    // Remove existing preview
    const existingPreview = wrapper.querySelector('.' + this.CSS.divider)
    if (existingPreview) {
      existingPreview.remove()
    }

    // Create new preview
    const divider = document.createElement('div')
    divider.className = this.CSS.divider
    
    const style = this.data.style || 'solid'
    const margin = '20px 0'
    
    switch (style) {
      case 'solid':
        divider.style.cssText = `
          height: 1px;
          background: #e2e8f0;
          margin: ${margin};
        `
        break
      case 'dashed':
        divider.style.cssText = `
          height: 1px;
          border-top: 1px dashed #e2e8f0;
          margin: ${margin};
        `
        break
      case 'dotted':
        divider.style.cssText = `
          height: 1px;
          border-top: 1px dotted #e2e8f0;
          margin: ${margin};
        `
        break
      case 'double':
        divider.style.cssText = `
          height: 3px;
          border-top: 1px solid #e2e8f0;
          border-bottom: 1px solid #e2e8f0;
          margin: ${margin};
        `
        break
      case 'thick':
        divider.style.cssText = `
          height: 3px;
          background: #e2e8f0;
          margin: ${margin};
        `
        break
      case 'fade':
        divider.style.cssText = `
          height: 1px;
          background: linear-gradient(to right, transparent, #e2e8f0 50%, transparent);
          margin: ${margin};
        `
        break
      default:
        divider.style.cssText = `
          height: 1px;
          background: #e2e8f0;
          margin: ${margin};
        `
    }

    wrapper.appendChild(divider)
  }

  save() {
    return {
      style: this.data.style || 'solid'
    }
  }

  static get conversionConfig() {
    return {
      export: 'text',
      import: 'text'
    }
  }
}
import { createApp, h } from 'vue'
import { Minus } from 'lucide-vue-next'

export class Divider {
	constructor({ data, api, readOnly }) {
		this.api = api
		this.data = data || {}
		this.readOnly = readOnly
		this.wrapper = null
	}

	static get isReadOnlySupported() {
		return true
	}

	static get toolbox() {
		const app = createApp({
			render: () => h(Minus, { size: 18, strokeWidth: 1.5, color: 'black' }),
		})

		const div = document.createElement('div')
		app.mount(div)

		return {
			title: 'Divider',
			icon: div.innerHTML,
		}
	}

	static get displayInToolbox() {
		return true
	}

	static get enableLineBreaks() {
		return false
	}

	render() {
		this.wrapper = document.createElement('div')
		this.wrapper.classList.add('lesson-divider')
		
		const divider = document.createElement('hr')
		divider.classList.add('lesson-divider__line')
		
		this.wrapper.appendChild(divider)

		return this.wrapper
	}

	save() {
		return {
			// No data to save for a simple divider
		}
	}

	validate() {
		return true
	}
}

export default Divider
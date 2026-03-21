import { LightningElement, api } from 'lwc';

export default class RightFitCheckbox extends LightningElement {
    @api value;
    @api label;
    @api checked = false;
    @api optionType = 'region';

    handleChange(event) {
        const checked = event.target.checked;
        this.dispatchEvent(
            new CustomEvent('optionchange', {
                detail: { value: this.value, checked, optionType: this.optionType },
                bubbles: true,
                composed: true
            })
        );
    }
}

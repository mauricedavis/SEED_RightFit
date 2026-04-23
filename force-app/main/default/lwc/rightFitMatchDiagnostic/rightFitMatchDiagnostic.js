import { LightningElement } from 'lwc';
import getMatchResultsBySelections from '@salesforce/apex/RightFitMatchService.getMatchResultsBySelections';
import getMatchPreviewBySelections from '@salesforce/apex/RightFitMatchService.getMatchPreviewBySelections';

const REGIONS = ['Far West', 'Great Lakes', 'Mid East', 'New England', 'Plains', 'Rocky Mountains', 'Southeast', 'Southwest'];
const SIZES = [
    { value: 'Small', label: 'Small (<5K)' },
    { value: 'Medium', label: 'Medium (5K–15K)' },
    { value: 'Large', label: 'Large (15K+)' }
];
const SETTINGS = ['Rural', 'Town', 'Suburban', 'Urban'];
const DEBOUNCE_MS = 300;
const MIN_MATCHES_SUCCESS_BADGE = 1;

export default class RightFitMatchDiagnostic extends LightningElement {
    gpaLow = '';
    gpaHigh = '';
    actLow = '';
    actHigh = '';
    satMathLow = '';
    satMathHigh = '';
    satVerbalLow = '';
    satVerbalHigh = '';
    testScoresOptional = false;
    settingAnyAll = false;

    selectedRegions = [];
    selectedSizes = [];
    selectedSettings = [];

    matchResults = [];
    matchCount = 0;
    suggestions = [];
    zeroMatchFeedback = null;
    isLoading = false;
    error = null;
    hasSearched = false;
    _debounceTimer = null;

    get regionCheckboxOptions() {
        return REGIONS.map((r) => ({ label: r, value: r }));
    }

    get sizeCheckboxOptions() {
        return SIZES.map((s) => ({ label: s.label, value: s.value }));
    }

    get settingCheckboxOptions() {
        return SETTINGS.map((s) => ({ label: s, value: s }));
    }

    get hasMinimumCriteria() {
        const hasRegion = this.selectedRegions && this.selectedRegions.length > 0;
        const hasSize = this.selectedSizes && this.selectedSizes.length > 0;
        const hasSetting = (this.selectedSettings && this.selectedSettings.length > 0) || this.settingAnyAll;
        return hasRegion || hasSize || hasSetting;
    }

    handleGpaChange(event) {
        const field = event.target.dataset.field;
        const val = event.target.value;
        if (field === 'low') this.gpaLow = val;
        else this.gpaHigh = val;
        this._scheduleRun();
    }

    handleActChange(event) {
        const field = event.target.dataset.field;
        const val = event.target.value;
        if (field === 'low') this.actLow = val;
        else this.actHigh = val;
        this._scheduleRun();
    }

    handleSatMathChange(event) {
        const field = event.target.dataset.field;
        const val = event.target.value;
        if (field === 'low') this.satMathLow = val;
        else this.satMathHigh = val;
        this._scheduleRun();
    }

    handleSatVerbalChange(event) {
        const field = event.target.dataset.field;
        const val = event.target.value;
        if (field === 'low') this.satVerbalLow = val;
        else this.satVerbalHigh = val;
        this._scheduleRun();
    }

    handleTestOptionalChange(event) {
        this.testScoresOptional = event.target.checked;
        this._runSearchImmediate();
    }

    handleRegionCheckboxChange(event) {
        const value = event?.detail?.value;
        this.selectedRegions = Array.isArray(value) ? [...value] : [];
        this._runSearchImmediate();
    }

    handleSizeCheckboxChange(event) {
        const value = event?.detail?.value;
        this.selectedSizes = Array.isArray(value) ? [...value] : [];
        this._runSearchImmediate();
    }

    handleSettingCheckboxChange(event) {
        const value = event?.detail?.value;
        this.selectedSettings = Array.isArray(value) ? [...value] : [];
        if (this.selectedSettings.length > 0) this.settingAnyAll = false;
        this._runSearchImmediate();
    }

    handleSettingAnyAllChange(event) {
        this.settingAnyAll = event.target.checked;
        if (this.settingAnyAll) this.selectedSettings = [];
        this._runSearchImmediate();
    }

    handleSelectAllRegions() {
        if (this.selectedRegions.length === REGIONS.length) {
            this.selectedRegions = [];
        } else {
            this.selectedRegions = [...REGIONS];
        }
        this._runSearchImmediate();
    }

    handleSelectAllSizes() {
        const allValues = SIZES.map((s) => s.value);
        if (this.selectedSizes.length === allValues.length) {
            this.selectedSizes = [];
        } else {
            this.selectedSizes = [...allValues];
        }
        this._runSearchImmediate();
    }

    _runSearchImmediate() {
        if (this._debounceTimer) clearTimeout(this._debounceTimer);
        this._debounceTimer = null;
        this._runSearch();
    }

    _scheduleRun() {
        if (this._debounceTimer) clearTimeout(this._debounceTimer);
        this._debounceTimer = setTimeout(() => {
            this._debounceTimer = null;
            this._runSearch();
        }, DEBOUNCE_MS);
    }

    async _runSearch() {
        if (!this.hasMinimumCriteria) {
            this.hasSearched = false;
            this.matchResults = [];
            this.matchCount = 0;
            this.suggestions = [];
            this.zeroMatchFeedback = null;
            this.error = null;
            return;
        }

        this.isLoading = true;
        this.error = null;
        this.hasSearched = true;

        const params = this._buildSelections();

        try {
            const [results, preview] = await Promise.all([
                getMatchResultsBySelections(params),
                getMatchPreviewBySelections(params)
            ]);

            this.matchResults = results || [];
            this.matchCount = this.matchResults.length;
            this.suggestions = preview?.suggestions || [];
            this.zeroMatchFeedback = preview?.zeroMatchFeedback || null;
        } catch (e) {
            this.error = e.body?.message || e.message || 'An error occurred';
            this.matchResults = [];
            this.matchCount = 0;
            this.suggestions = [];
            this.zeroMatchFeedback = null;
        } finally {
            this.isLoading = false;
        }
    }

    _buildSelections() {
        const regions = this.selectedRegions && this.selectedRegions.length > 0 ? [...this.selectedRegions] : [];
        const sizes = this.selectedSizes && this.selectedSizes.length > 0 ? [...this.selectedSizes] : [];
        let collegeSettings = [];
        if (this.settingAnyAll) {
            collegeSettings = [...SETTINGS];
        } else if (this.selectedSettings && this.selectedSettings.length > 0) {
            collegeSettings = [...this.selectedSettings];
        }
        return {
            regions,
            sizes,
            collegeSettings,
            testScoresOptional: this.testScoresOptional === true,
            gpaLow: this._toNum(this.gpaLow),
            gpaHigh: this._toNum(this.gpaHigh),
            actLow: this._toNum(this.actLow),
            actHigh: this._toNum(this.actHigh),
            satMathLow: this._toNum(this.satMathLow),
            satMathHigh: this._toNum(this.satMathHigh),
            satVerbalLow: this._toNum(this.satVerbalLow),
            satVerbalHigh: this._toNum(this.satVerbalHigh)
        };
    }

    _toNum(val) {
        if (val == null || val === '') return null;
        const n = Number(val);
        return isNaN(n) ? null : n;
    }

    get activeFiltersSummary() {
        const parts = ['Rated: Green & Yellow only (Red excluded)'];
        if (this.selectedRegions && this.selectedRegions.length > 0) parts.push('Region: ' + this.selectedRegions.join(', '));
        if (this.selectedSizes && this.selectedSizes.length > 0) parts.push('Size: ' + this.selectedSizes.join(', '));
        if (this.settingAnyAll) {
            parts.push('Setting: Any');
        } else if (this.selectedSettings && this.selectedSettings.length > 0) {
            parts.push('Setting: ' + this.selectedSettings.join(', '));
        }
        const gpaL = this._toNum(this.gpaLow);
        const gpaH = this._toNum(this.gpaHigh);
        if (gpaL != null && gpaH != null) parts.push('GPA: ' + gpaL + '–' + gpaH);
        const actL = this._toNum(this.actLow);
        const actH = this._toNum(this.actHigh);
        if (actL != null && actH != null) parts.push('ACT: ' + actL + '–' + actH);
        const satML = this._toNum(this.satMathLow);
        const satMH = this._toNum(this.satMathHigh);
        if (satML != null && satMH != null) parts.push('SAT Math: ' + satML + '–' + satMH);
        const satVL = this._toNum(this.satVerbalLow);
        const satVH = this._toNum(this.satVerbalHigh);
        if (satVL != null && satVH != null) parts.push('SAT Verbal: ' + satVL + '–' + satVH);
        if (this.testScoresOptional) parts.push('Test Optional');
        return parts.join(' | ');
    }

    get resultsList() {
        return (this.matchResults || []).map((r, i) => ({
            ...r,
            key: `row-${i}`,
            medianGpaDisplay: r.medianGpa != null ? r.medianGpa : '—',
            medianActDisplay: r.medianAct != null ? r.medianAct : '—',
            medianSatMathDisplay: r.medianSatMath != null ? r.medianSatMath : '—',
            medianSatVerbalDisplay: r.medianSatVerbal != null ? r.medianSatVerbal : '—',
            rightFitDisplay: r.rightFitMatchColor || '—',
            accountUrl: `/${r.accountId}`
        }));
    }

    get resultBadgeClass() {
        if (this.matchCount >= MIN_MATCHES_SUCCESS_BADGE) return 'slds-theme_success';
        return 'slds-theme_error';
    }

    get suggestionList() {
        return (this.suggestions || []).map((text, i) => ({ id: `s${i}`, text }));
    }

    get showSuggestions() {
        return this.suggestions && this.suggestions.length > 0;
    }

    get showZeroMatchFeedback() {
        return this.zeroMatchFeedback && this.matchCount === 0;
    }

    get zeroMatchCauses() {
        return (this.zeroMatchFeedback?.possibleCauses || []).map((text, i) => ({ id: `c${i}`, text }));
    }

    get zeroMatchSteps() {
        return (this.zeroMatchFeedback?.nextSteps || []).map((text, i) => ({ id: `n${i}`, text }));
    }
}

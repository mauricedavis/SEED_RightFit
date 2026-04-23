import { LightningElement, api } from 'lwc';
import getMatchPreviewByRecordId from '@salesforce/apex/RightFitMatchService.getMatchPreviewByRecordId';
import getMatchPreviewBySelections from '@salesforce/apex/RightFitMatchService.getMatchPreviewBySelections';

const MIN_MATCHES_TO_PROCEED = 1;

export default class RightFitMatchPreview extends LightningElement {
    _lastRefreshKey = 0;
    _lastCriteriaId = '';
    _studentMatchCriteriaId;
    @api
    get studentMatchCriteriaId() { return this._studentMatchCriteriaId; }
    set studentMatchCriteriaId(val) {
        const id = val != null ? String(val) : '';
        if (this._lastCriteriaId !== id && id) {
            const wasReturning = this._lastCriteriaId.length > 0;
            this._lastCriteriaId = id;
            this._studentMatchCriteriaId = val;
            if (wasReturning) {
                this.hasRun = false;
                setTimeout(() => this.runPreview(), 0);
            }
        } else {
            this._studentMatchCriteriaId = val;
            if (id) this._lastCriteriaId = id;
        }
    }
    @api gpaLow;
    @api gpaHigh;
    @api actLow;
    @api actHigh;
    @api satMathLow;
    @api satMathHigh;
    @api satVerbalLow;
    @api satVerbalHigh;
    @api testScoresOptional;
    @api regionsString;
    @api sizesString;
    @api collegeSettingsString;
    @api collegeSetting;
    @api
    get refreshKey() { return this._lastRefreshKey; }
    set refreshKey(val) {
        const next = val != null ? Number(val) : 0;
        if (this._lastRefreshKey !== next && this.studentMatchCriteriaId) {
            const wasReturning = this._lastRefreshKey !== 0;
            this._lastRefreshKey = next;
            if (wasReturning) {
                this.hasRun = false;
                setTimeout(() => this.runPreview(), 0);
            }
        } else if (this._lastRefreshKey !== next) {
            this._lastRefreshKey = next;
        }
    }

    matchCount = 0;
    canSubmit = false;
    suggestions = [];
    zeroMatchFeedback = null;
    isLoading = false;
    error;
    hasRun = false;
    hasSearched = false;
    _lastRunTime = 0;
    static RECALC_DEBOUNCE_MS = 500;

    connectedCallback() {
        this.hasRun = false;
    }

    renderedCallback() {
        if (this.isLoading) return;
        const hasCriteria = (this._studentMatchCriteriaId || this.studentMatchCriteriaId) || this.regionsString || this.sizesString || this.collegeSettingsString || this.gpaLow != null || this.gpaHigh != null;
        if (!hasCriteria) return;
        const now = Date.now();
        const timeSinceLastRun = now - this._lastRunTime;
        const shouldRun = !this.hasRun || (this.hasSearched && timeSinceLastRun > RightFitMatchPreview.RECALC_DEBOUNCE_MS);
        if (shouldRun) {
            this.hasRun = true;
            this._lastRunTime = now;
            this.runPreview();
        }
    }

    @api
    get canProceed() {
        return this.canSubmit;
    }

    handleRecalculate() {
        this.hasRun = false;
        this.runPreview();
    }

    @api
    async runPreview() {
        this.hasRun = true;
        this.isLoading = true;
        this.error = null;
        try {
            let result;
            if (this.studentMatchCriteriaId) {
                result = await getMatchPreviewByRecordId({ studentMatchCriteriaId: this.studentMatchCriteriaId });
            } else {
                const params = this._buildSelectionsForPreview();
                result = await getMatchPreviewBySelections(params);
            }
            this.matchCount = result.matchCount ?? 0;
            this.canSubmit = result.canSubmit === true;
            this.suggestions = result.suggestions ?? [];
            this.zeroMatchFeedback = result.zeroMatchFeedback ?? null;
        } catch (e) {
            this.error = e.body?.message || e.message || 'An error occurred';
            this.matchCount = 0;
            this.canSubmit = false;
            this.suggestions = [];
            this.zeroMatchFeedback = null;
        } finally {
            this.isLoading = false;
            this.hasSearched = true;
        }
    }

    _buildSelectionsForPreview() {
        const regions = this._parseList(this.regionsString);
        const sizes = this._parseList(this.sizesString);
        const collegeSettings = this._parseList(this.collegeSettingsString);
        return {
            regions: regions,
            sizes: sizes,
            collegeSettings: collegeSettings,
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

    _parseList(str) {
        if (!str || typeof str !== 'string') return [];
        return str.split(',').map((s) => s.trim()).filter(Boolean);
    }

    _toNum(val) {
        if (val == null || val === '') return null;
        const n = Number(val);
        return isNaN(n) ? null : n;
    }

    get statusClass() {
        if (this.matchCount >= MIN_MATCHES_TO_PROCEED) return 'slds-theme_success';
        return 'slds-theme_error';
    }

    get statusLabel() {
        if (this.matchCount >= MIN_MATCHES_TO_PROCEED) {
            return `${this.matchCount} college${this.matchCount === 1 ? '' : 's'} matched — you can proceed!`;
        }
        return 'No colleges matched your criteria.';
    }

    get showSuggestions() {
        return this.suggestions && this.suggestions.length > 0;
    }

    get suggestionList() {
        return (this.suggestions || []).map((text, i) => ({ id: `s${i}`, text }));
    }

    get showZeroMatchFeedback() {
        return this.zeroMatchFeedback && this.matchCount === 0;
    }

    get showRecalculateButton() {
        return this.hasSearched && !this.canSubmit && !this.isLoading;
    }

    get zeroMatchCauses() {
        return (this.zeroMatchFeedback?.possibleCauses || []).map((text, i) => ({ id: `c${i}`, text }));
    }

    get zeroMatchSteps() {
        return (this.zeroMatchFeedback?.nextSteps || []).map((text, i) => ({ id: `n${i}`, text }));
    }
}
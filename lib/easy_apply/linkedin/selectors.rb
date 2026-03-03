# frozen_string_literal: true

module EasyApply
  module LinkedIn
    module Selectors
      # Job search results page
      JOB_CARD = '.job-card-container'
      JOB_CARD_LINK = '.job-card-container__link'
      JOB_CARD_TITLE = '.job-card-list__title'
      JOB_CARD_COMPANY = '.job-card-container__primary-description'
      JOB_CARD_LOCATION = '.job-card-container__metadata-item'
      JOB_LIST = '.jobs-search-results-list'
      JOB_LIST_ITEMS = '.jobs-search-results__list-item'
      PAGINATION_NEXT = 'button[aria-label="View next page"]'
      NO_RESULTS = '.jobs-search-no-results-banner'

      # Job detail panel
      JOB_DETAIL_PANEL = '.jobs-search__job-details'
      JOB_TITLE = '.job-details-jobs-unified-top-card__job-title'
      JOB_COMPANY = '.job-details-jobs-unified-top-card__company-name'
      JOB_LOCATION_DETAIL = '.job-details-jobs-unified-top-card__bullet'
      JOB_DESCRIPTION = '.jobs-description__content'
      JOB_DESCRIPTION_TEXT = '.jobs-description-content__text'
      JOB_CRITERIA = '.job-details-jobs-unified-top-card__job-insight'
      JOB_ID_ATTR = 'data-job-id'

      # Easy Apply
      EASY_APPLY_BUTTON = '.jobs-apply-button'
      EASY_APPLY_MODAL = '.jobs-easy-apply-modal'
      EASY_APPLY_CONTENT = '.jobs-easy-apply-content'
      EASY_APPLY_FORM = '.jobs-easy-apply-form-section__grouping'

      # Modal actions
      MODAL_NEXT = "button[aria-label='Continue to next step']"
      MODAL_REVIEW = "button[aria-label='Review your application']"
      MODAL_SUBMIT = "button[aria-label='Submit application']"
      MODAL_CLOSE = "button[aria-label='Dismiss']"
      MODAL_DISCARD = "button[data-control-name='discard_application_confirm_btn']"

      # Form fields
      FORM_INPUT = 'input[type="text"], input[type="number"], input[type="tel"], input[type="email"]'
      FORM_SELECT = 'select'
      FORM_TEXTAREA = 'textarea'
      FORM_RADIO = 'input[type="radio"]'
      FORM_CHECKBOX = 'input[type="checkbox"]'
      FORM_LABEL = 'label'
      FORM_FIELDSET_LEGEND = 'legend'

      # Success indicators
      APPLICATION_SENT = '.artdeco-inline-feedback--success'
      POST_APPLY_MODAL = '.artdeco-modal__content'

      # Filters
      EASY_APPLY_FILTER = "button[aria-label='Easy Apply filter.']"
      FILTER_EASY_APPLY = '#searchFilter_applyWithLinkedin'
    end
  end
end

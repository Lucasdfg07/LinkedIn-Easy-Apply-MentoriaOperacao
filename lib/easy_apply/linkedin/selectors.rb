# frozen_string_literal: true

module EasyApply
  module LinkedIn
    module Selectors
      # Job search results page (updated 2026-03)
      JOB_CARD = '.job-card-container'
      JOB_CARD_CLICKABLE = '.job-card-container--clickable'
      JOB_CARD_LINK = '.job-card-container a'
      JOB_CARD_TITLE = '.job-card-list__title, .artdeco-entity-lockup__title'
      JOB_CARD_COMPANY = '.artdeco-entity-lockup__subtitle, .job-card-container__primary-description'
      JOB_CARD_LOCATION = '.artdeco-entity-lockup__caption, .job-card-container__metadata-item'
      JOB_LIST_ITEMS = 'li[data-occludable-job-id]'
      JOB_LIST_ITEMS_ALT = '.scaffold-layout__list-item'
      JOB_DATA_ID = '[data-job-id]'
      PAGINATION_NEXT = 'button[aria-label="View next page"]'
      NO_RESULTS = '.jobs-search-no-results-banner'

      # Job detail panel
      JOB_DETAIL_PANEL = '.jobs-search__job-details'
      JOB_TITLE = '.job-details-jobs-unified-top-card__job-title, .t-24.job-details-jobs'
      JOB_COMPANY = '.job-details-jobs-unified-top-card__company-name'
      JOB_LOCATION_DETAIL = '.job-details-jobs-unified-top-card__bullet'
      JOB_DESCRIPTION = '.jobs-description__content, .jobs-description'
      JOB_DESCRIPTION_TEXT = '.jobs-description-content__text, .jobs-description__content .jobs-box__html-content'
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

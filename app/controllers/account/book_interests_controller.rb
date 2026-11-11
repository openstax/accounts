module Account
  # Add or remove a book on the user's "books you're interested in" list. The list
  # is Salesforce's Subject_Interest__c, mirrored in users.which_books; an edit is
  # a delta (see PushBookInterest), so what other systems wrote is never replaced.
  class BookInterestsController < Newflow::BaseController
    before_action :newflow_authenticate_user!
    before_action :require_instructor

    def create
      abbreviation = params[:abbreviation].to_s.strip
      title = AdoptionBookCatalog.new.title_for(abbreviation)
      return redirect_to(back_to_list, alert: t('book_interest.unknown_book')) if title.nil?

      if listed.include?(abbreviation)
        return redirect_to(back_to_list, notice: t('book_interest.already', title: escape(title)))
      end

      change(add: [abbreviation])
      redirect_to back_to_list, notice: t('book_interest.added', title: escape(title))
    end

    def destroy
      abbreviation = params[:abbreviation].to_s.strip
      return redirect_to(back_to_list, alert: t('book_interest.not_listed')) unless listed.include?(abbreviation)

      title = AdoptionBookCatalog.new.title_for(abbreviation) || abbreviation
      change(remove: [abbreviation])
      redirect_to back_to_list, notice: t('book_interest.removed', title: escape(title))
    end

    private

    def listed
      BookInterest.parse(current_user.which_books)
    end

    # Which_books changes now so the list is right after the redirect; Salesforce
    # catches up in the background. A "Considering it" answer for a removed book
    # is marked sent, or the nightly sweep would add the book straight back.
    def change(add: [], remove: [])
      BookInterest.update_user!(current_user, add: add, remove: remove)
      mark_removed_answers_sent(remove)
      SecurityLog.create!(user: current_user, event_type: :book_interest_changed,
                          event_data: { added: add, removed: remove })
      PushBookInterest.perform_later(user: current_user, add: add, remove: remove)
    end

    def mark_removed_answers_sent(abbreviations)
      return if abbreviations.empty?

      current_user.adoption_reports.unpushed.where(status: 'considering', salesforce_book_name: abbreviations)
                  .update_all(salesforce_pushed_at: Time.zone.now)
    end

    def require_instructor
      return unless current_user.student? || current_user.self_learner?

      redirect_to back_to_list, alert: t('book_interest.not_available')
    end

    # Flashes render html_safe, so the title is escaped here.
    def escape(text)
      ERB::Util.html_escape(text).to_str
    end

    def back_to_list
      account_books_path(anchor: 'book-interests')
    end
  end
end

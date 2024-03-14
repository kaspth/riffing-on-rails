# Recurring Reports: Allow users to manage a report builder for recurring reports with questions of various types,
# given out to a set of users or organizations that must complete the report at regular intervals (weekly, monthly, yearly).
# Keep track of report completion status for each round of reporting, and make it so answers can be aggregated and compared,
# both across users/orgs and over time. Allow questions to be added or removed over time.

class Report::Template
  has_many :questions

  belongs_to :timing
end

class Report::Delivery
  belongs_to :report
  has_many :reply_requests

  # delivered_at

  def deliver_from(template)
    template.users.each do |user|

    end
  end
end

class Reports::Templates::Questions::ReplacementsController
  def create
    @template = Report.find(params[:report_id]).template
    @question = @template.questions.find(params[:question_id])

    ActiveRecord::Base.transaction do
      new_question = @template.questions.create!(params[:template].permit!)

      Delivery::Submission.where(template_question: @question).update_all template_question_id: new_question.id
      @question.destroy!
    end
  end
end

class Report::Template::Question
  has_many :delivery_submissions
end

class Report::Delivery::Question
  belongs_to :template_question
end

class Report::Delivery::Submission
  belongs_to :user
  has_many :question_submissions
  # has_many :questions, through: :question_submissions

  def fulfilled?
    question_submissions.all?(&:fullfilled?)
  end
end

class Report::Question::Submission
  belongs_to :delivery_submission
  belongs_to :delivery_question

  def fulfilled? = fulfilled_at?
end

class Report::Template::Timing
  enum :kind, %i[ weekly monthly yearly ]

  def next_window_from(past_delivery)
    case kind
    when :weekly  then past_delivery.last_sent_at + 1.week
    when :monthly then 1.month.from_now
    when :yearly  then 1.year.from_now
    end
  end
end

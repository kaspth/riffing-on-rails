# A tool to help contract lawyers by organizing a cluttered collection of disorganized contracts and their versions in Google Drive (different/inconsistent naming, unreliable timestamps).

# The tool aims to classify contracts, order their versions chronologically, and summarize changes between versions.

# It updates the document index upon each new upload, whether the folder has been previously processed or not.


# # Full Spec

# I’m part of a team helping contract lawyers be more efficient at work. One of the core features is AI-assisted document version management.

# Context
# When a lawyer is negotiating a deal, there are a few different contracts involved, and each contract has many versions that go back and forth by email, and lawyers usually manually save the attachments into a shared folder. But this folder is a mess. The attachments have different names, the timestamps are unreliable, so it’s not useful when someone looks back at the file later on (ie, if there is a dispute regarding the contracts). They can’t make sense of the history of negotiations.

# Business goal
# So we are building a tool to help organize this messy dump of documents (PDF+Word), with unreliable timestamps and file names, and we will use LLMs to take a best guess at:

# (a) what are the different types of contracts that are part of the deal,
# (b) identify the different versions of each contract and the order of the versions (in time), and
# (c) provide an incremental summary of the change between each version of the same contract.
# Existing data

# The existing database has a table of clients, and each client has many deals.
# Each deal also has a link to a google drive folder URL, and this folder is a big messy soup of different deal contracts (each contract may have many versions)
# Feature

# Every time a new contract is uploaded to a deal folder in Google Drive:

# If the folder hasn’t been processed yet, we want to try and build an organized index of documents/versions (best guess)
# If the folder has already been processed, just deal with the new uploaded file and update the index

class Client
  has_many :deals
end

class Deal
  has_many :documents
end

class Document
  has_many :versions
end

class Document::Version
  belongs_to :document, optional: true

  has_one_attached :file

  after_create_commit :consolidate

  def consolidate
    deal.consolidate deal.metadata
  end
end

class Document::Index
end

class Deals::UploadsController < ApplicationController
  def create
    Current.deal.process_batch files: params[:files]
  end
end

class Deal::Processor::Batch
  belongs_to :deal
  has_many :files

  def schedule_later

  end
end

class Deal::Processor::File
  belongs_to :batch
  delegate :deal, to: :batch

  after_create_commit :process_later

  has_one_attached :file

  enum status: %i[ pending processing processed errored ]

  def process
    unless processed?
      Document::Version.create! file:, deal:
      processed!
    end
  rescue
    errored!
    raise
  end

  def process_later
  end
end

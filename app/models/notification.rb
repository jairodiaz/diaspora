#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.
#
class Notification
  require File.join(Rails.root, 'lib/diaspora/web_socket')
  include MongoMapper::Document
  include Diaspora::Socketable

  key :target_id, ObjectId
  key :kind, String
  key :unread, Boolean, :default => true
  key :person_ids, Array, :typecast => 'ObjectId'

  belongs_to :user
  many :people, :class => Person, :in => :person_ids

  timestamps!

  attr_accessible :target_id, :kind, :user_id, :person_id, :unread

  def self.for(user, opts={})
    self.where(opts.merge!(:user_id => user.id)).order('updated_at desc')
  end

  def self.notify(user, object, person)
    if object.respond_to? :notification_type
      if kind = object.notification_type(user, person)
        if object.is_a? Comment
          n = concatenate_or_create(user, object.post, person, kind)
        else
          n = make_notification(user, object, person, kind)
        end
        n.socket_to_uid(user.id, :actor => person) if n
        n
      end
    end
  end

private

  def self.concatenate_or_create(user, object, person, kind)
    if n = Notification.where(:target_id => object.id,
                               :kind => kind,
                               :user_id => user.id).first
      n.people << person
      n.save!
      n
    else
      n  = make_notification(user, object, person, kind)
    end
  end

  def self.make_notification(user, object, person, kind)
    n = Notification.new(:target_id => object.id,
                        :kind => kind,
                        :user_id => user.id)
    n.people << person
    n.save!
    n
  end
end

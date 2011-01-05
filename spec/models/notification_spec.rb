#   Copyright (c) 2010, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

require 'spec_helper'


describe Notification do
  before do
    @sm = Factory(:status_message)
    @person = Factory(:person)
    @user = make_user
    @user2 = make_user
    @aspect  = @user.aspects.create(:name => "dudes")
    @opts = {:target_id => @sm.id, :kind => @sm.class.name, :people => [@person], :user_id => @user.id}
    @note = Notification.new(@opts)
    @note.people =[ @person]
  end

  it 'contains a type' do
    @note.kind.should == StatusMessage.name
  end

  it 'contains a target_id' do
    @note.target_id.should == @sm.id
  end

  it 'has many people' do
    @note.associations[:people].type.should == :many
  end

  describe '.for' do
    it 'returns all of a users notifications' do
      user2 = make_user
      4.times do
        Notification.create(@opts)
      end

      @opts.delete(:user_id)
      Notification.create(@opts.merge(:user_id => user2.id))

      Notification.for(@user).count.should == 4
    end
  end

  describe '.notify' do
    it 'does not call Notification.create if the object does not notification_type' do
      Notification.should_not_receive(:make_notification)
      Notification.notify(@user, @sm, @person)
    end

    it 'does call Notification.create if the object does not notification_type' do
      request = Request.instantiate(:from => @user.person, :to => @user2.person, :into => @aspect)
      Notification.should_receive(:make_notification).once
      Notification.notify(@user, request, @person)
    end

    it 'sockets to the recipient' do
      request = Request.instantiate(:from => @user.person, :to => @user2.person, :into => @aspect)
      opts = {:target_id => request.id,
              :kind => request.notification_type(@user, @person),
              :person_id => @person.id,
              :user_id => @user.id}

      n = Notification.create(opts)
      Notification.stub!(:make_notification).and_return n

      n.should_receive(:socket_to_uid).once
      Notification.notify(@user, request, @person)
    end

    it "updates the notification with a more people if one already exists" do
      @aspect2 = @user2.aspects.create(:name => "winners")
      connect_users(@user, @aspect, @user2, @aspect2)
      @user3 = make_user
      @aspect3 = @user.aspects.create(:name => "winners")
      connect_users(@user, @aspect, @user3, @aspect3)
      sm = @user.post(:status_message, :message => "comment!", :to => :all)
      @user2.reload.comment("hey", :on => sm)
      @user3.reload.comment("way", :on => sm)
      Notification.where(:user_id => @user.id,:target_id => sm.id).first.people.count.should == 2
    end
  end
end


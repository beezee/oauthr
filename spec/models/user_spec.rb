require 'spec_helper'

describe User do

  describe '#valid?' do

    describe 'with no password' do
      let(:user) { User.new(email: 'user@email.com') }

      describe 'on create' do

        it 'is not valid' do
          expect(user.valid?).to be_false
          expect(user.errors.full_messages.size).to be(1)
          expect(user.errors.full_messages.first).to(
            eq("Password can't be blank"))
        end
      end

      describe 'on update' do

        it 'is valid' do
          expect(user.valid?(:update)).to be_true
        end
      end
    end

    describe 'with no email' do
      let(:user) { User.new(password: 'foo') }

      it 'is invalid' do
        expect(user.valid?).to be_false
        expect(user.errors.full_messages.size).to be(1)
        expect(user.errors.full_messages.first).to(
          eq("Email is invalid"))
      end
    end

    describe 'with invalid email' do
      let(:user) { User.new(email: 'bademail@', password: 'foo') }

      it 'is invalid' do
        expect(user.valid?).to be_false
        expect(user.errors.full_messages.size).to be(1)
        expect(user.errors.full_messages.first).to(
          eq("Email is invalid"))
      end
    end
  end
end

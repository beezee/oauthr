require 'spec_helper'

describe AuthenticationHelper do

  describe '#current_user' do
    let(:session) { {token: 'foo'} }
    let(:authenticator) do
      AuthenticationHelper::Authenticator.
        for_session_and_request(session, nil)
    end

    describe 'when session[:token] matches a persisted users session_token' do
      let(:user) { User.new }
      before do
        expect(User).to(
          receive(:find_by_session_token).with('foo').
          and_return(user))
      end

      describe 'when user was updated within the last 10 min' do
        before { user.updated_at = (9.minutes + 55.seconds).ago }

        it 'returns the matching user' do
          expect(authenticator.current_user).to be(user)
        end
      end

      describe 'when user was updated more than 10 min ago' do
        before { user.updated_at = 10.minutes.ago }

        it 'returns nil' do
          expect(authenticator.current_user).to be_nil
        end
      end
    end

    describe 'when session[:token] doesnt match a persisted users session_token' do
      before do
        expect(User).to(
          receive(:find_by_session_token).with('foo').
          and_return(nil))
      end
      
      it 'returns nil' do
        expect(authenticator.current_user).to be_nil
      end
    end
  end

  describe '#login_redirect_params' do
    let(:request) do
      env = {'PATH_INFO' => 'foo', 
        'rack.url_scheme' => 'https', 'HTTP_HOST' => 'localtest/'}
      ActionDispatch::Request.new(env)
    end
    let(:authenticator) do
      AuthenticationHelper::Authenticator.
        for_session_and_request(nil, request)
    end

    it 'returns the correct params for a redirect to login' do
      expected = {controller: '/users', action: 'login',
                    redirect_to: 'https://localtest/foo'}
      expect(authenticator.login_redirect_params).to eq(expected)
    end
  end

  describe '#authenticate_user' do
    let(:authenticator) do
      AuthenticationHelper::Authenticator.
        for_session_and_request(nil, nil)
    end
    
    describe 'when provided email matches persisted user' do
      let(:user) {  u = User.new(password: 'bar') }
      before do
        expect(User).to(
          receive(:find_by_email).with('foo@bar').
          and_return(user))
      end
      
      describe 'when password matches with found user' do

        it 'returns the found user' do
          expect(authenticator.authenticate_user('foo@bar', 'bar')).to be(user)
        end
      end

      describe 'when password doesnt match with found user' do

        it 'returns false' do
          expect(authenticator.authenticate_user('foo@bar', 'barr')).to be_false
        end
      end
    end

    describe 'when provided email doesnt match persisted user' do
      
      it 'returns nil' do
        expect(authenticator.authenticate_user('not@found', 'foo')).to be_nil
      end
    end
  end

  # test heavily since its the moment privileges 
  # are granted and it's based entirely on side effects
  describe '#create_session_for_user!' do
    let(:user) { User.new }
    let(:session) { {} }
    let(:authenticator) do
      AuthenticationHelper::Authenticator.
        for_session_and_request(session, nil)
    end
    before do
      expect_any_instance_of(UUID).to receive(:generate).and_return('foo')
    end

    shared_examples "session/user synchronization" do

      it 'leaves session[:token] and user.session_token equal' do
        authenticator.create_session_for_user!(user)
        expect(session[:token]).to eq('foo')
        expect(user.session_token).to eq('foo')
        expect(user.session_token).to eq(session[:token])
      end
    end

    shared_examples "change of user.session_token from value" do |from|
      
      it "changes user.session token" do
        expect { authenticator.create_session_for_user!(user) }.to(
          change { user.session_token }.from(from).to('foo'))
      end
    end

    shared_examples "change of session[:token] from value" do |from|
      
      it "changes session[:token]" do
        expect { authenticator.create_session_for_user!(user) }.to(
          change { session[:token] }.from(from).to('foo'))
      end
    end

    shared_examples "no change of user.session_token" do

      it 'does not change user.session_token' do
        expect { authenticator.create_session_for_user!(user) }.to_not(
          change{user.session_token})
      end

      it 'attempts to save user anyway to extend login expiration' do
        expect(user).to receive(:save)
        authenticator.create_session_for_user!(user)
      end
    end

    shared_examples "no change of session[:token]" do

      it 'does not change session[:token]' do
        expect { authenticator.create_session_for_user!(user) }.to_not(
          change{session[:token]})
      end
    end

    shared_examples 'all permutations of session[:token] states' do |user_expect_params|

      # this should never happen
      describe 'when session[:token] matches new token' do
        before { session[:token] = 'foo' }
        
        it_behaves_like *user_expect_params
        it_behaves_like 'no change of session[:token]'
        it_behaves_like 'session/user synchronization'
      end

      describe 'when session[:token] exists but doesnt match new token' do
        before { session[:token] = 'notfoo' }

        it_behaves_like *user_expect_params
        it_behaves_like 'change of session[:token] from value', 'notfoo'
        it_behaves_like 'session/user synchronization'
      end

      describe 'when session[:token] is nil' do

        it_behaves_like *user_expect_params
        it_behaves_like 'change of session[:token] from value', nil
        it_behaves_like 'session/user synchronization'
      end
    end

    describe 'when user.session_token is nil' do
      
      it_behaves_like 'all permutations of session[:token] states', 
        ['change of user.session_token from value', nil]
    end

    describe 'when user.session_token exists but doesnt match new token' do
      before { user.session_token = 'notfoo' }

      it_behaves_like 'all permutations of session[:token] states', 
        ['change of user.session_token from value', 'notfoo']
    end

    # this should never happen
    describe 'when user.session_token matches new token' do
      before { user.session_token = 'foo' }

      it_behaves_like 'all permutations of session[:token] states',
        ['no change of user.session_token']
    end
  end
end

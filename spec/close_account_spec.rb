require File.expand_path("spec_helper", File.dirname(__FILE__))

describe 'Rodauth close_account feature' do
  it "should support closing accounts when passwords are not required" do
    rodauth do
      enable :login, :close_account
      close_account_requires_password? false
    end
    roda do |r|
      r.rodauth
      r.root{view(:content=>"")}
    end

    visit '/login'
    fill_in 'Login', :with=>'foo@example.com'
    fill_in 'Password', :with=>'0123456789'
    click_button 'Login'
    page.current_path.must_equal '/'

    visit '/close-account'
    click_button 'Close Account'
    page.current_path.must_equal '/'

    Account.select_map(:status_id).must_equal [3]
  end

  it "should delete accounts when skip_status_checks? is true" do
    rodauth do
      enable :login, :close_account
      close_account_requires_password? false
      skip_status_checks? true
    end
    roda do |r|
      r.rodauth
      r.root{view(:content=>"")}
    end

    visit '/login'
    fill_in 'Login', :with=>'foo@example.com'
    fill_in 'Password', :with=>'0123456789'
    click_button 'Login'
    page.current_path.must_equal '/'

    visit '/close-account'
    click_button 'Close Account'
    page.current_path.must_equal '/'

    Account.count.must_equal 0
  end

  it "should support closing accounts when passwords are required" do
    rodauth do
      enable :login, :close_account
    end
    roda do |r|
      r.rodauth
      r.root{view(:content=>"")}
    end

    visit '/login'
    fill_in 'Login', :with=>'foo@example.com'
    fill_in 'Password', :with=>'0123456789'
    click_button 'Login'
    page.current_path.must_equal '/'

    visit '/close-account'
    fill_in 'Password', :with=>'012345678'
    click_button 'Close Account'
    page.find('#error_flash').text.must_equal "There was an error closing your account"
    page.html.must_include("invalid password")
    Account.select_map(:status_id).must_equal [2]

    fill_in 'Password', :with=>'0123456789'
    click_button 'Close Account'
    page.find('#notice_flash').text.must_equal "Your account has been closed"
    page.current_path.must_equal '/'

    Account.select_map(:status_id).must_equal [3]
  end

  it "should support closing accounts with overrides" do
    rodauth do
      enable :login, :close_account
      close_account do
        account.email = 'foo@bar.com'
        super()
      end
      close_account_route 'close'
      close_account_redirect '/login'
    end
    roda do |r|
      r.rodauth
      r.root{""}
    end

    visit '/login'
    fill_in 'Login', :with=>'foo@example.com'
    fill_in 'Password', :with=>'0123456789'
    click_button 'Login'
    page.current_path.must_equal '/'

    visit '/close'
    page.title.must_equal 'Close Account'
    fill_in 'Password', :with=>'0123456789'
    click_button 'Close Account'
    page.find('#notice_flash').text.must_equal "Your account has been closed"
    page.current_path.must_equal '/login'

    Account.select_map(:status_id).must_equal [3]
    Account.select_map(:email).must_equal ['foo@bar.com']
  end

  it "should close accounts when account_password_hash_column is set" do
    rodauth do
      enable :create_account, :close_account
      close_account_requires_password? false
      create_account_autologin? true
      account_password_hash_column :ph
    end
    roda do |r|
      r.rodauth
      r.root{view(:content=>"")}
    end

    visit '/create-account'
    fill_in 'Login', :with=>'foo2@example.com'
    fill_in 'Confirm Login', :with=>'foo2@example.com'
    fill_in 'Password', :with=>'apple2'
    fill_in 'Confirm Password', :with=>'apple2'
    click_button 'Create Account'

    visit '/close-account'
    click_button 'Close Account'
    page.current_path.must_equal '/'

    Account.last.status_id.must_equal 3
  end
end

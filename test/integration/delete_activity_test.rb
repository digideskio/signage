require 'test_helper'

class DeleteActivityTest < Capybara::Rails::TestCase
  
  setup do
    sign_in users(:james)
    signs(:default).owners << users(:james)
    slides(:standard).owners << users(:james)
  end

  test "creating and deleting a slide" do
    assert_difference 'PublicActivity::Activity.count', 2 do
      visit new_slide_path
      fill_in 'slide_menu_name', with: 'yo'
      select 'Standard', from: 'slide_template'
      click_button 'Next'
      click_link 'Delete'
    end
    visit home_index_path
    assert_equal 200, page.status_code
  end

  test "updating and deleting a slide" do
    assert_difference 'PublicActivity::Activity.count', 2 do
      visit edit_slide_path(slides(:standard))
      fill_in 'slide_menu_name', with: 'updated'
      select 'Standard', from: 'slide_template'
      click_button 'Update Slide'
      click_link 'Edit'
      click_link 'Delete'
    end
    visit home_index_path
    assert_equal 200, page.status_code
  end

  test "creating and deleting a sign" do
    assert_difference 'PublicActivity::Activity.count', 2 do
      visit new_sign_path
      fill_in 'sign_name', with: 'created a sign'
      click_button 'Create Sign'
      click_link 'Delete'
    end
    visit home_index_path
    assert_equal 200, page.status_code
  end

  test "updating and deleting a sign" do
    assert_difference 'PublicActivity::Activity.count', 2 do
      visit edit_sign_path(signs(:default))
      fill_in 'sign_name', with: 'updated a sign'
      click_button 'Update Sign'
      click_link 'Delete'
    end
    visit home_index_path
    assert_equal 200, page.status_code
  end
end

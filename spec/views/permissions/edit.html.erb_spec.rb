require 'rails_helper'

RSpec.describe 'permissions/edit', type: :view do
  before do
    @permission = assign(:permission, Permission.create!(
                                        permission_id: 1,
                                        title: 'MyString',
                                        is_admin: false,
                                        create_modify_events: false,
                                        create_modify_announcements: false,
                                        view_all_attendances: false
                                      ))
  end

  it 'renders the edit permission form' do
    render

    assert_select 'form[action=?][method=?]', permission_path(@permission), 'post' do
      assert_select 'input[name=?]', 'permission[permission_id]'

      assert_select 'input[name=?]', 'permission[title]'

      assert_select 'input[name=?]', 'permission[is_admin]'

      assert_select 'input[name=?]', 'permission[create_modify_events]'

      assert_select 'input[name=?]', 'permission[create_modify_announcements]'

      assert_select 'input[name=?]', 'permission[view_all_attendances]'
    end
  end
end

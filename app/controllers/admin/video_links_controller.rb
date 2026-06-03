module Admin
  class VideoLinksController < Admin::ApplicationController
    # Pre-fill the polymorphic linkable from query params so links like
    # /admin/video_links/new?linkable_type=Goal&linkable_id=42 open the form
    # with the goal (or match) already selected.
    def new
      resource = new_resource
      if params[:linkable_type].in?(%w[Match Goal]) && params[:linkable_id].present?
        resource.linkable = params[:linkable_type].constantize.find_by(id: params[:linkable_id])
      end
      authorize_resource(resource)
      render locals: { page: Administrate::Page::Form.new(dashboard, resource) }
    end

    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes(action_name)).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end

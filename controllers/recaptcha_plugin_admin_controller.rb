class RecaptchaPluginAdminController < PluginAdminController

  append_view_path File.join(File.dirname(__FILE__) + '/../views')

  def index
  end

  def update
    if @environment.update_attributes(params[:environment])
      session[:notice] = _('Captcha configuration updated successfully.')
    else
      session[:notice] = _('Captcha configuration could not be saved.')
    end
    render :action => 'index'
  end

end

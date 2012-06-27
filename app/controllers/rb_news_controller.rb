include RbCommonHelper

class RbNewsController < RbApplicationController
  unloadable

  def show
    @project = Project.find(params[:project_id])
    @news = @project.news.find(:all, :limit => 4, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
    render :action => 'show', :layout => 'empty'
  end
end

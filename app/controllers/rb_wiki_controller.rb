include RbCommonHelper
include AttachmentsHelper

class RbWikiController < RbApplicationController
  unloadable

  def show
    @project = Project.find(params[:project_id])
    @wiki = @project.wiki
    
    @page = @wiki.find_page(@wiki.start_page)
    if @page
      @content = @page.content
      @editable = editable?
    end

    render :action => 'show', :layout => 'empty'
  end
  
  def editable?(page = @page)
    page.editable_by?(User.current)
  end
end

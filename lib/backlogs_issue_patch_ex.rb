#coding:utf-8
require_dependency 'issue'

module Backlogs
  module IssuePatchEx
  
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      before_save :require_tasks_done_when_story_done
      before_save :require_estimated_hours_when_status_update
      before_save :require_assignee_when_status_in_progress
      before_save :note_required_on_close
    end
  end
  
  module InstanceMethods
    def require_tasks_done_when_story_done
      return unless project.module_enabled?('backlogs')
      return unless Setting.plugin_redmine_backlogs[:story_trackers].map{|t|t.to_i}.include?(tracker_id)
      return unless status_id_changed?
      return unless IssueStatus.find(status_id).is_closed?
      return if children.select {|task| !task.closed?}.empty?

      errors[:base] << :tasks_must_be_done_when_story_done
      false
    end
    
    def require_estimated_hours_when_status_update
      return unless project.module_enabled?('backlogs')
      return unless tracker_id == Setting.plugin_redmine_backlogs[:task_tracker].to_i
      return if new_record?
      return unless status_id_changed?
      return if IssueStatus.find(status_id).is_closed? and status.backlog == :failure

      return if estimated_hours and estimated_hours > 0.0
      
      errors[:base] << :estimated_hours_is_empty
      false
    end

    def require_assignee_when_status_in_progress
      return unless project.module_enabled?('backlogs')
      return unless tracker_id == Setting.plugin_redmine_backlogs[:task_tracker].to_i
      return if new_record?
      return unless status_id_changed?
      return if IssueStatus.find(status_id).is_closed? and status.backlog == :failure

      return if assigned_to
      
      errors[:base] << :assignee_is_empty
      false
    end

    # original is https://github.com/ajwalters/redmine_require_closing_note/tree
    def note_required_on_close
      if require_note?
        # New records do _NOT_ have a notes field
        if @current_journal.notes.blank?
          errors[:base] << :require_note
          return false
        end
      end
      true #= valid_save ? before_save_without_note_required_on_close : false
    end
    
    private
    
    def require_note?
      status = IssueStatus.find(status_id)
      !new_record? && status_id_changed? && !IssueStatus.find(status_id_was).is_closed? && status.is_closed? && status.backlog == :failure
    end
  end
  end
end

Issue.send(:include, Backlogs::IssuePatchEx) unless Issue.included_modules.include? Backlogs::IssuePatchEx


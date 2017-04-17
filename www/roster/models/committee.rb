class Committee
  def self.serialize(id, env)
    response = {}

    pmc = ASF::Committee.find(id)
    committers = ASF::Group.find(id).members
    return if pmc.members.empty? and committers.empty?

    ASF::Committee.load_committee_info
    people = ASF::Person.preload('cn', (pmc.members + committers).uniq)

    lists = ASF::Mail.lists(true).select do |list, mode|
      list =~ /^#{pmc.mail_list}\b/
    end

    moderators = nil

    if pmc.roster.include? env.user or ASF::Person.find(env.user).asf_member?
      if File.exist? LIST_MODS
         mail_list = "#{pmc.mail_list}.apache.org"
         moderators = File.read(LIST_MODS).split(/\n\n/).map do |stanza|
           list = stanza.match(/(\w+\.apache\.org)\/(.*?)\//)
           next unless list[1] == mail_list
 
           ["#{list[2]}@#{list[1]}", stanza.scan(/^(.*@.*)/).flatten.sort]
        end
        moderators = moderators.compact.to_h
      end
    else
      lists = lists.select {|list, mode| mode == 'public'}
    end

    response = {
      id: id,
      chair: pmc.chair && pmc.chair.id,
      display_name: pmc.display_name,
      description: pmc.description,
      schedule: pmc.schedule,
      report: pmc.report,
      site: pmc.site,
      established: pmc.established,
      ldap: Hash[pmc.members.map {|person| [person.id, person.cn]}],
      committers: Hash[committers.map {|person| [person.id, person.cn]}],
      asfmembers: (ASF.members & people).map(&:id),
      roster: pmc.roster,
      mail: Hash[lists.sort],
      moderators: moderators,
    }

    response
  end
end

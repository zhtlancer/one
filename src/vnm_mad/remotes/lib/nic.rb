# -------------------------------------------------------------------------- #
# Copyright 2002-2015, OpenNebula Project (OpenNebula.org), C12G Labs        #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

module VNMMAD

module VNMNetwork

    # This class represents the NICS of a VM, it provides a factory method
    # to create VMs of the given hyprtvisor
    class Nics < Array
        def initialize(hypervisor)
            case hypervisor
            when "kvm"
                @nicClass = NicKVM
            when "xen"
                @nicClass = NicXen
            when "vmware"
                @nicClass = NicVMware
            end
        end

        def new_nic
            @nicClass.new
        end
    end

    ############################################################################
    # Hypervisor specific implementation of network interfaces. Each class
    # implements the following interface:
    #   - get_info to populste the VM.vm_info Hash
    #   - get_tap to set the [:tap] attribute with the associated NIC
    ############################################################################

    # A NIC using KVM. This class implements functions to get the physical
    # interface that the NIC is using, based on the MAC address
    class NicKVM < Hash
        def initialize
            super(nil)
        end

        # Get the VM information with virsh dumpxml
        def get_info(vm)
            if vm.deploy_id
                deploy_id = vm.deploy_id
            else
                deploy_id = vm['DEPLOY_ID']
            end

            if deploy_id and vm.vm_info[:dumpxml].nil?
                vm.vm_info[:dumpxml] = `#{VNMNetwork::COMMANDS[:virsh]} dumpxml #{deploy_id} 2>/dev/null`

                vm.vm_info.each_key do |k|
                    vm.vm_info[k] = nil if vm.vm_info[k].to_s.strip.empty?
                end
            end
        end

        # Look for the tap in
        #   devices/interface[@type='bridge']/mac[@address='<mac>']/../target"
        def get_tap(vm)
            dumpxml = vm.vm_info[:dumpxml]

            if dumpxml
                dumpxml_root = REXML::Document.new(dumpxml).root

                xpath = "devices/interface[@type='bridge']/" \
                        "mac[@address='#{self[:mac]}']/../target"

                tap = dumpxml_root.elements[xpath]

                self[:tap] = tap.attributes['dev'] if tap
            end

            self
        end
    end


    # A NIC using Xen. This class implements functions to get the physical interface
    # that the NIC is using
    class NicXen < Hash
        def initialize
            super(nil)
        end

        def get_info(vm)
            if vm.deploy_id
                deploy_id = vm.deploy_id
            else
                deploy_id = vm['DEPLOY_ID']
            end

            if deploy_id and (vm.vm_info[:domid].nil? or vm.vm_info[:networks].nil?)
                vm.vm_info[:domid]    =`#{VNMNetwork::COMMANDS[:xm]} domid #{deploy_id}`.strip
                vm.vm_info[:networks] =`#{VNMNetwork::COMMANDS[:xm]} network-list #{deploy_id}`

                vm.vm_info.each_key do |k|
                    vm.vm_info[k] = nil if vm.vm_info[k].to_s.strip.empty?
                end
            end
        end

        def get_tap(vm)
            domid = vm.vm_info[:domid]

            if domid
                networks = vm.vm_info[:networks].split("\n")[1..-1]
                networks.each do |net|
                    n = net.split

                    iface_id  = n[0]
                    iface_mac = n[2]

                    if iface_mac == self[:mac]
                        self[:tap] = "vif#{domid}.#{iface_id}"
                        break
                    end
                end
            end
            self
        end
    end

    # A NIC using VMware. This class implements functions to get the physical interface
    # that the NIC is using
    class NicVMware < Hash
        def initialize
            super(nil)
        end

        def get_info(vm)
        end

        def get_tap(vm)
            self
        end
    end

end

end
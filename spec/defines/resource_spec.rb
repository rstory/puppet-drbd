require 'spec_helper'

describe 'drbd::resource', type: :define do
  let(:title) { 'mock_drbd_resource' }
  let(:default_facts) do
    { concat_basedir: '/dne' }
  end
  let(:default_params) do
    {
      disk: '/dev/mock_disk',
      initial_setup: true
    }
  end

  context 'on any node' do
    [true, false].each do |primary|
      let :facts do
        { ipaddress: '10.16.0.1' }.merge(default_facts)
      end
      let :params do
        {
          cluster: 'mock_cluster',
          ha_primary: primary
        }.merge(default_params)
      end

      describe "with no drbd::resource's exported" do
        it { should contain_class('drbd') }
        it { should contain_concat__fragment('mock_drbd_resource drbd header') }
        it { should contain_concat__fragment('mock_drbd_resource drbd footer') }
        it { should_not contain_service('drbd') }
        it { should_not contain_exec('initialize DRBD metadata for mock_drbd_resource') }
        it { should_not contain_exec('enable DRBD resource mock_drbd_resource') }
        it { should_not contain_exec('drbd_make_primary_mock_drbd_resource') }
        it { should_not contain_exec('drbd_format_volume_mock_drbd_resource') }
        it { should_not contain_mount('/drbd/mock_drbd_resource') }
        it { Puppet.expects(:warning).never }
      end
    end
  end
  context 'on the primary clustered node' do
    let :facts do
      { ipaddress: '10.16.0.1' }.merge(default_facts)
    end
    let :params do
      {
        cluster: 'mock_cluster',
        ha_primary: true
      }.merge(default_params)
    end

    describe "with no drbd::resource's exported" do
      let :exported_resources do
      end

      it { should contain_concat__fragment('mock_drbd_resource mock_cluster primary resource') }
      it { should_not contain_concat__fragment('mock_drbd_resource mock_cluster secondary resource') }
    end

    describe "with secondary's drbd::resource exported" do
      let :exported_resources do
        {
          'concat::fragment' =>
          {
            'mock_drbd_resource mock_cluster secondary resource' =>
            {
              target: '/etc/drbd.d/mock_drbd_resource.res'
            }
          }
        }
      end

      it { should contain_service('drbd') }
      it { should contain_concat__fragment('mock_drbd_resource mock_cluster primary resource') }
      it { should contain_concat__fragment('mock_drbd_resource mock_cluster secondary resource') }
      it { should contain_exec('initialize DRBD metadata for mock_drbd_resource') }
      it { should contain_exec('enable DRBD resource mock_drbd_resource') }
      it { should contain_exec('drbd_make_primary_mock_drbd_resource') }
      it { should contain_exec('drbd_format_volume_mock_drbd_resource') }
      it { should contain_mount('/drbd/mock_drbd_resource') }
      it { Puppet.expects(:warning).never }
    end

    describe "with other cluster's drbd::resource exported" do
      let :exported_resources do
        {
          'concat::fragment' =>
          {
            'mock_drbd_resource mock_cluster secondary resource' =>
            {
              target: '/etc/drbd.d/mock_drbd_resource.res'
            },
            'mock_drbd_resource other_cluster secondary resource' =>
            {
              target: '/etc/drbd.d/mock_drbd_resource.res'
            }
          }
        }
      end

      it { should contain_concat__fragment('mock_drbd_resource mock_cluster secondary resource') }
      it { should_not contain_concat__fragment('mock_drbd_resource other_cluster secondary resource') }
    end
  end

  context 'on the secondary clustered node' do
    let :facts do
      { ipaddress: '10.16.0.2' }.merge(default_facts)
    end
    let :params do
      {
        cluster: 'mock_cluster',
        ha_primary: false
      }.merge(default_params)
    end

    describe 'with no drbd::resource exported' do
      let(:exported_resources) {}

      it { should_not contain_concat__fragment('mock_drbd_resource mock_cluster primary resource') }
      it { should contain_concat__fragment('mock_drbd_resource mock_cluster secondary resource') }
    end

    describe "with primary's drbd::resource exported" do
      let :exported_resources do
        {
          'concat::fragment' =>
          {
            'mock_drbd_resource mock_cluster primary resource' =>
            {
              target: '/etc/drbd.d/mock_drbd_resource.res'
            }
          }
        }
      end

      it { should contain_service('drbd') }
      it { should contain_concat__fragment('mock_drbd_resource mock_cluster primary resource') }
      it { should contain_concat__fragment('mock_drbd_resource mock_cluster secondary resource') }
      it { should contain_exec('initialize DRBD metadata for mock_drbd_resource') }
      it { should contain_exec('enable DRBD resource mock_drbd_resource') }
      it { should_not contain_exec('drbd_make_primary_mock_drbd_resource') }
      it { should_not contain_exec('drbd_format_volume_mock_drbd_resource') }
      it { should_not contain_mount('/drbd/mock_drbd_resource') }
    end
  end

  context 'on the primary undefined node' do
    let:facts do
      default_facts
    end
    let :params do
      { ha_primary: false }.merge(default_params)
    end

    it { expect { should contain_service('drbd') }.to raise_error Puppet::Error, %r{cluster} }
  end

  context 'on the primary static node' do
    let :facts do
      { ipaddress: '10.16.0.1' }.merge(default_facts)
    end
    let :params do
      {
        host1: 'mock_primary',
        host2: 'mock_secondary',
        ip1: '10.16.0.1',
        ip2: '10.16.0.2',
        ha_primary: true
      }.merge(default_params)
    end

    describe "with secondary's drbd::resource exported" do
      let :exported_resources do
        {
          'concat::fragment' =>
          {
            'mock_drbd_resource static secondary resource' =>
            {
              target: '/etc/drbd.d/mock_drbd_resource.res'
            }
          }
        }
      end

      it do
        should contain_drbd__resource__enable('mock_drbd_resource').with(
          'cluster' => 'static'
      )
      end
      it { should contain_service('drbd') }
      it { should contain_concat__fragment('mock_drbd_resource static primary resource') }
      it { should contain_concat__fragment('mock_drbd_resource static secondary resource') }
      it { should contain_exec('initialize DRBD metadata for mock_drbd_resource') }
      it { should contain_exec('enable DRBD resource mock_drbd_resource') }
      it { should contain_exec('drbd_make_primary_mock_drbd_resource') }
      it { should contain_exec('drbd_format_volume_mock_drbd_resource') }
      it { should contain_mount('/drbd/mock_drbd_resource') }
      it { Puppet.expects(:warning).never }
    end
  end

  context 'on the secondary static node' do
    let :facts do
      { ipaddress: '10.16.0.2' }.merge(default_facts)
    end
    let :params do
      {
        host1: 'mock_primary',
        host2: 'mock_secondary',
        ip1: '10.16.0.1',
        ip2: '10.16.0.2',
        ha_primary: false
      }.merge(default_params)
    end

    describe "with primary's drbd::resource exported" do
      let :exported_resources do
        {
          'concat::fragment' =>
          {
            'mock_drbd_resource static primary resource' =>
              {
                target: '/etc/drbd.d/mock_drbd_resource.res'
              }
          }
        }
      end

      it do
        should contain_drbd__resource__enable('mock_drbd_resource').with(
          'cluster' => 'static'
      )
      end
      it { should contain_service('drbd') }
      it { should contain_concat__fragment('mock_drbd_resource static primary resource') }
      it { should contain_concat__fragment('mock_drbd_resource static secondary resource') }
      it { should contain_exec('initialize DRBD metadata for mock_drbd_resource') }
      it { should contain_exec('enable DRBD resource mock_drbd_resource') }
      it { should_not contain_exec('drbd_make_primary_mock_drbd_resource') }
      it { should_not contain_exec('drbd_format_volume_mock_drbd_resource') }
      it { should_not contain_mount('/drbd/mock_drbd_resource') }
      it { Puppet.expects(:warning).never }
    end
  end
end

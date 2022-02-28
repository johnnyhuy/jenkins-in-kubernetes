import org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud
import jenkins.model.Jenkins

println 'Loading Kubernetes configuration'

Jenkins jenkins = Jenkins.getInstance()
KubernetesCloud cloud = new KubernetesCloud('kubernetes')
cloud.setServerUrl('https://kubernetes.default.svc')
jenkins.clouds.add(cloud)

println 'Loading Kubernetes configuration completed'

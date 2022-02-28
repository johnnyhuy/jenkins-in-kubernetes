import org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud
import jenkins.model.Jenkins

Jenkins jenkins = Jenkins.getInstance()
KubernetesCloud cloud = new KubernetesCloud('kubernetes')
cloud.setServerUrl('https://kubernetes.default.svc')
jenkins.cloud.add(cloud)
